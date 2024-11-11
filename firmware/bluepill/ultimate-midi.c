/* 
   MIDI/80 for the TRS-80 Model 1, III, and 4
   Copyright (C) 2024 Michael Wessel aka LambdaMikel 

   This program is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation; either version 3 of the License, or
   (at your option) any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program; if not, write to the Free Software Foundation,
   Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301  USA

   MIDI/80 for the TRS-80 Model 1, III, and 4
   Copyright (C) 2024 Michael Wessel
   MIDI/80 comes with ABSOLUTELY NO WARRANTY. 
   This is free software, and you are welcome to redistribute it
   under certain conditions. 

*/ 

//
// MIDI/80 
// License: GPL 3 
// 
// (C) 2024 Michael Wessel 
// mailto:miacwess@gmail.com
// https://www.michael-wessel.info
// 

#include <stdint.h>
#include <libopencm3/stm32/timer.h>
#include <libopencm3/stm32/rcc.h>
#include <libopencm3/stm32/gpio.h>
#include <libopencm3/stm32/usart.h>
#include <libopencm3/stm32/exti.h>
#include <libopencm3/cm3/nvic.h>

#define BUFFER_SIZE 256

static volatile  uint16_t counter = 0; 

static volatile  uint32_t midi_in[BUFFER_SIZE];

static volatile  uint8_t write_cursor = 0;
static volatile  uint8_t read_cursor = 0;

static volatile  uint8_t data = 0;

static volatile  uint16_t byte_avail = 0;
static volatile  uint16_t midi_cur8 = 0;

static volatile  uint8_t m3_to_midi_out = 0;
static volatile  uint8_t m3_to_s2 = 0;

static volatile  uint8_t midi_in_to_midi_out = 0;
static volatile  uint8_t midi_in_to_s2 = 0;

//
//
//

// input channels: write from M3, MIDI IN DIN (MIDI input channel) 
static volatile  uint8_t read_data_from_m3_act = 0;
static volatile  uint8_t read_data_from_midi_in_act = 0;

// output channels: read from M3, MIDI out DIN, S2 
static volatile  uint8_t send_data_to_s2_act = 0;
static volatile  uint8_t send_data_to_midi_out_act = 0;
static volatile  uint8_t send_data_to_m3_act = 0;  // M3 reads data 


//
//
//


#define z80_run gpio_set(GPIOA, GPIO8)
#define z80_halt gpio_clear(GPIOA, GPIO8)


//
//
//

static void delay(void) {
  for (uint32_t i = 0; i < 500000; i++)
    __asm__("nop");
}

static void short_delay(void) {
  for (uint32_t i = 0; i < 100000; i++)
    __asm__("nop");
}

static void medium_delay(void) {
  for (uint32_t i = 0; i < 300000; i++)
    __asm__("nop");
}

/*
  static void very_short_delay(void) {
  for (uint32_t i = 0; i < 10000; i++)
  __asm__("nop");
  }
*/

//
//
//

static void databus_output(void) {

  // rcc_periph_clock_enable(RCC_GPIOB);

  // disable READ LATCH
  gpio_set(GPIOC,GPIO15);
 
  gpio_set_mode(GPIOB,GPIO_MODE_OUTPUT_50_MHZ,
		GPIO_CNF_OUTPUT_PUSHPULL,
		
		//GPIO_CNF_OUTPUT_ALTFN_PUSHPULL,

		//GPIOB,GPIO_MODE_OUTPUT_2_MHZ,
		//GPIO_CNF_OUTPUT_OPENDRAIN,
		
		GPIO8  | GPIO9  | GPIO10 | GPIO11 |  
		GPIO12 | GPIO13 | GPIO14 | GPIO15 );

  // always present the last INP(8) on the databus! 
  gpio_port_write(GPIOB, midi_cur8);
  
}

static void databus_input(void) {

  // rcc_periph_clock_enable(RCC_GPIOB);

  // enable READ LATCH
  gpio_clear(GPIOC,GPIO15);
  
  gpio_set_mode(GPIOB,GPIO_MODE_INPUT,
		GPIO_CNF_INPUT_FLOAT,
		//GPIO_CNF_INPUT_PULL_UPDOWN, 
		//GPIO_CNF_OUTPUT_OPENDRAIN,
		GPIO8  | GPIO9  | GPIO10 | GPIO11 |  
		GPIO12 | GPIO13 | GPIO14 | GPIO15 ); 

}

//
// UART Configuration (we have 2, one for S2, one for MIDI IN / OUT) 
//

static void usartsetup(void) {

  nvic_set_priority(NVIC_USART1_IRQ,0x00);

  // needed? 
  //nvic_enable_irq(RCC_AFIO);

  //rcc_periph_clock_enable(RCC_GPIOA);
  rcc_periph_clock_enable(RCC_USART1);

  // enable MIDI IN Midifeather RX IRQ UART 
  nvic_enable_irq(NVIC_USART1_IRQ);

  //
  // MIDI OUT USART - PA9, PA10 = MIDI OUT, MIDI IN
  // 

  // UART1_TX on PA9
  gpio_set_mode(GPIOA,
		GPIO_MODE_OUTPUT_50_MHZ,
		GPIO_CNF_OUTPUT_ALTFN_PUSHPULL,
		GPIO_USART1_TX);

  usart_set_baudrate(USART1,31250);
  usart_set_databits(USART1,8);
  usart_set_stopbits(USART1,USART_STOPBITS_1);
  usart_set_mode(USART1,USART_MODE_TX_RX);
  usart_set_parity(USART1,USART_PARITY_NONE);
  usart_set_flow_control(USART1,USART_FLOWCONTROL_NONE);
  /* Enable USART1 Receive interrupt. */
  USART_CR1(USART1) |= USART_CR1_RXNEIE;
  usart_enable(USART1);

  //
  // S2 USART - PA2 / MIDI TTL 
  //
  
  //rcc_periph_clock_enable(RCC_GPIOA);
  rcc_periph_clock_enable(RCC_USART2);

  // UART2_TX on PA2 
  gpio_set_mode(GPIOA,
		GPIO_MODE_OUTPUT_50_MHZ,
		GPIO_CNF_OUTPUT_ALTFN_PUSHPULL,
		GPIO_USART2_TX);

  usart_set_baudrate(USART2,31250);
  usart_set_databits(USART2,8);
  usart_set_stopbits(USART2,USART_STOPBITS_1);
  usart_set_mode(USART2,USART_MODE_TX);
  usart_set_parity(USART2,USART_PARITY_NONE);
  usart_set_flow_control(USART2,USART_FLOWCONTROL_NONE);
  usart_enable(USART2);
  
}

//
// GPIO Configuration
// 

static void gpio_setup(void) {
  
  // Enabled Clocks 
  rcc_periph_clock_enable(RCC_GPIOC);
  rcc_periph_clock_enable(RCC_GPIOB);
  rcc_periph_clock_enable(RCC_GPIOA);

  // Z80 READY PA8

  gpio_set_mode(GPIOA,GPIO_MODE_OUTPUT_50_MHZ,
		// GPIO_CNF_OUTPUT_PUSHPULL, 
		// GPIO_CNF_OUTPUT_ALTFN_PUSHPULL,
		GPIO_CNF_OUTPUT_OPENDRAIN,
		GPIO8);

  /*
  gpio_set_mode(GPIOA,GPIO_MODE_INPUT,
		GPIO_CNF_INPUT_FLOAT,
		GPIO8);
  */

  // READ2 PA12 &FBFE 
  gpio_set_mode(GPIOA,GPIO_MODE_INPUT,
		// GPIO_CNF_INPUT_PULL_UPDOWN,
		GPIO_CNF_INPUT_FLOAT,
		GPIO12);
  
  // READ1 PB4 &FBEE 
  gpio_set_mode(GPIOB,GPIO_MODE_INPUT,
		// GPIO_CNF_INPUT_PULL_UPDOWN,
		GPIO_CNF_INPUT_FLOAT,
		GPIO4);
  
  // WRITE PB6 &FBEE 
  gpio_set_mode(GPIOB,GPIO_MODE_INPUT,
		// GPIO_CNF_INPUT_PULL_UPDOWN,
		GPIO_CNF_INPUT_FLOAT,
		GPIO6);	
  
  // LED PC13 & S2 RESET 
  gpio_set_mode(GPIOC,GPIO_MODE_OUTPUT_50_MHZ,
		GPIO_CNF_OUTPUT_PUSHPULL,GPIO13);

  // READ LATCH OUTPUT 
  gpio_set_mode(GPIOC,GPIO_MODE_OUTPUT_50_MHZ,
		GPIO_CNF_OUTPUT_PUSHPULL,GPIO15);


  // PA7 PA6 PA5 PA4 DIL SWITCH
  gpio_set_mode(GPIOA,GPIO_MODE_INPUT,
		GPIO_CNF_INPUT_PULL_UPDOWN,
		GPIO7 | GPIO6 | GPIO5 | GPIO4);	

  //
  // 5 LEDs: PB0, PB1, PB7, PB5, PC14 
  //

  // LED1 = PB0 
  gpio_set_mode(GPIOB,GPIO_MODE_OUTPUT_50_MHZ,
		GPIO_CNF_OUTPUT_PUSHPULL,GPIO0);

  // LED2 = PB1 
  gpio_set_mode(GPIOB,GPIO_MODE_OUTPUT_50_MHZ,
		GPIO_CNF_OUTPUT_PUSHPULL,GPIO1);
  
  // LED3 = PB7 
  gpio_set_mode(GPIOB,GPIO_MODE_OUTPUT_50_MHZ,
		GPIO_CNF_OUTPUT_PUSHPULL,GPIO7); 

  // LED4 = PB5
  gpio_set_mode(GPIOB,GPIO_MODE_OUTPUT_50_MHZ,
		GPIO_CNF_OUTPUT_PUSHPULL,GPIO5); 

  // LED5 = PC14
  gpio_set_mode(GPIOC,GPIO_MODE_OUTPUT_50_MHZ,
		GPIO_CNF_OUTPUT_PUSHPULL,GPIO14); 


  //
  // Configure PB0 - PB8 - PB15 as Databus 
  // Default is output -
  // possible due to glue logic 74LS374, 74LS244
  // 
  
  databus_output();

  //
  // Setup USARTs
  //

  usartsetup(); 
    
}

//
// Configure ISRs 
//

static void exti_setup(void){
  
  // Enable AFIO clock.
    
  rcc_periph_clock_enable(RCC_AFIO);
    
  // READ1 PB4

  nvic_enable_irq(NVIC_EXTI4_IRQ); 
  exti_select_source(EXTI4,GPIOB);
  exti_set_trigger(EXTI4, EXTI_TRIGGER_RISING);
  nvic_set_priority(EXTI4,0x01);
  exti_enable_request(EXTI4);

  // WRITE PB6 

  nvic_enable_irq(NVIC_EXTI9_5_IRQ);
  exti_select_source(EXTI6,GPIOB);
  exti_set_trigger(EXTI6, EXTI_TRIGGER_RISING);
  nvic_set_priority(EXTI6,0x01);
  exti_enable_request(EXTI6);

  // READ2 PA12

  nvic_enable_irq(NVIC_EXTI15_10_IRQ);	
  exti_select_source(EXTI12,GPIOA);
  exti_set_trigger(EXTI12, EXTI_TRIGGER_RISING);
  nvic_set_priority(EXTI12,0x01);
  exti_enable_request(EXTI12);

}

//
// ISR Handlers 
//


static volatile  uint8_t isr_active = 0; 

void exti4_isr(){

  gpio_port_write(GPIOB, midi_cur8);

  if (! isr_active) {

    z80_halt;
    isr_active = 1;
   
    // READ1 request from M3
    // Fetch a byte from the MIDI buffer 
    // READ1 REQUEST PB4 = Port 8 = GAL 16V8 PIN 18 

    // this either outputs 0 or the byte, if available -
    // see code below for "prefetch" of the midi_cur8 byte:

    // get the output to the port as fast as possible, 
    
    // gpio_port_write(GPIOB, midi_cur8);

    // other ops can wait: 
    
    send_data_to_m3_act = 1;
    
    //
    //
    //    

    if (byte_avail) {

      read_cursor++; 

      // 8bit automatic overflow!
      // if ( read_cursor == BUFFER_SIZE)
      //   read_cursor = 0; 
	
      byte_avail = read_cursor == write_cursor ? 0 : (1 << 8);
    }

    if (byte_avail) {
      
      midi_cur8 = midi_in[read_cursor];
      
    } else
      
      midi_cur8 = 0; 
      
    //
    //
    //
    
    exti_reset_request(EXTI4);
    isr_active = 0;

    z80_run;

  }
  
} 

void exti15_10_isr(){

  gpio_port_write(GPIOB, byte_avail);    

  if (! isr_active) {

    z80_halt;
    isr_active = 1;

    // READ2 request from M3
    // Check if a byte is available in the MIDI buffer 
    // READ2 REQUEST PA12 = Port 9 = GAL 16V8 PIN 19 

    // get the output to the port as fast as possible, 

    gpio_port_write(GPIOB, byte_avail);    

    if (byte_avail) {
      midi_cur8 = midi_in[read_cursor]; 
    }
    
    // other ops can wait: 
    
    send_data_to_m3_act = 1;        
    
    exti_reset_request(EXTI12);
    isr_active = 0;

    // prefetch... (or not) 
    gpio_port_write(GPIOB, midi_cur8);

    z80_run;
    
  }

} 


//
//
//

void exti9_5_isr(){

  if (  gpio_get(GPIOB,GPIO6)) {

    z80_halt;
        
    // WRITE request from M3
    // WRITE REQUEST PB6 = Port 8 = GAL 16V8 PIN 15
    
    databus_input();
    counter = gpio_port_read(GPIOB) >> 8;
    databus_output(); 

    read_data_from_m3_act = 1;
    
    exti_reset_request(EXTI6);
    
    if (m3_to_midi_out) {      
      usart_send(USART1, counter);
      send_data_to_midi_out_act = 1; 
    }
    
    if (m3_to_s2) {   
      usart_send(USART2, counter);
      send_data_to_s2_act = 1; 
    }

    z80_run;

  }
 
}

//
// USART MIDI IN ISR 
//

void usart1_isr(void) {

  z80_halt; 

  // incoming MIDI data from MIDI IN 

  data = usart_recv(USART1);

  //
  // buffer incoming MIDI byte immediately 
  // 


  // 8bit automatic overflow
  // if (next_write_cursor == BUFFER_SIZE)
  //  next_write_cursor = 0;

  
  midi_in[write_cursor] = ( data << 8);
  write_cursor++;
  byte_avail = (1 << 8) ;

  //
  // send to USARTs 
  //  

  if (midi_in_to_midi_out) {
    send_data_to_midi_out_act = 1; 
    usart_send(USART1, data);
  }
  
  if (midi_in_to_s2) {
    send_data_to_s2_act = 1; 
    usart_send(USART2, data);
  }
  
  read_data_from_midi_in_act = 1;

  z80_run;

}

//
// Main 
// 

int main(void) {

  rcc_clock_setup_in_hse_8mhz_out_72mhz(); // For "blue pill"

  gpio_setup();
  z80_run;

  // Onboard LED & S2 Reset
  gpio_set(GPIOA,GPIO13);


  //
  // Read DIP switch 
  //

  m3_to_s2 = gpio_get(GPIOA, GPIO4) ? 1 : 0; 
  m3_to_midi_out = gpio_get(GPIOA, GPIO5) ? 1 : 0;
  
  midi_in_to_s2 = gpio_get(GPIOA, GPIO6) ? 1 : 0; 
  midi_in_to_midi_out = gpio_get(GPIOA, GPIO7) ? 1 : 0;
 
  //
  // Display DIP switch settings on LEDs 
  //

  for (int i = 0; i < 3; i++) {
    
    gpio_set(GPIOB,GPIO0);
    medium_delay();
    gpio_clear(GPIOB,GPIO0);
  
    gpio_set(GPIOB,GPIO1);
    medium_delay();
    gpio_clear(GPIOB,GPIO1);
  
    gpio_set(GPIOB,GPIO7);
    medium_delay();
    gpio_clear(GPIOB,GPIO7);
  
    gpio_set(GPIOB,GPIO5);
    medium_delay();
    gpio_clear(GPIOB,GPIO5);
  
    gpio_set(GPIOC,GPIO14);
    medium_delay();  
    gpio_clear(GPIOC,GPIO14);

    gpio_set(GPIOB,GPIO5);
    medium_delay();
    gpio_clear(GPIOB,GPIO5);
  
    gpio_set(GPIOB,GPIO7);
    medium_delay();
    gpio_clear(GPIOB,GPIO7);

    gpio_set(GPIOB,GPIO1);
    medium_delay();
    gpio_clear(GPIOB,GPIO1);

    gpio_set(GPIOB,GPIO0);
    medium_delay();
    gpio_clear(GPIOB,GPIO0);

    medium_delay();
  
  }

  //
  // Reset S2 
  // 

  gpio_clear(GPIOC,GPIO13);

  //
  //
  //

  for (int i = 0; i < 10; i++) {
    if (m3_to_s2) // -> LED 1 = PB0 
      gpio_set(GPIOB,GPIO0);
    else 
      gpio_clear(GPIOB,GPIO0);

    if (m3_to_midi_out)  // -> LED 2 = PB1
      gpio_set(GPIOB,GPIO1);
    else
      gpio_clear(GPIOB,GPIO1);

    if (midi_in_to_s2) // -> LED 3 = PB7 
      gpio_set(GPIOB,GPIO7);
    else
      gpio_clear(GPIOB,GPIO7);

    if (midi_in_to_midi_out) // -> LED 4 = PB5
      gpio_set(GPIOB,GPIO5);
    else
      gpio_clear(GPIOB,GPIO5);    

    gpio_set(GPIOC,GPIO14); // -> LED5 = PC14 = "Power on blink"

    medium_delay(); 

    gpio_clear(GPIOB,GPIO0);
    gpio_clear(GPIOB,GPIO1);
    gpio_clear(GPIOB,GPIO7);
    gpio_clear(GPIOB,GPIO5);    
    gpio_set(GPIOC,GPIO14); 

    medium_delay(); 

  }
  
  //
  // Onboard LED & S2 Reset done
  //
  
  gpio_set(GPIOC,GPIO13);

  //
  // 
  // 
  
  delay();
  delay();
  delay();
  delay();
  delay();  
  delay();

  //
  //
  //

  isr_active = 0;   
  exti_setup(); 	  

  //
  // Main loop 
  // 

  while (1) {
    
    short_delay();

    if (read_data_from_m3_act) // LED 1
      gpio_set(GPIOB,GPIO0);
    else 
      gpio_clear(GPIOB,GPIO0);
    
    if (read_data_from_midi_in_act) // LED 2 
      gpio_set(GPIOB,GPIO1);
    else
      gpio_clear(GPIOB,GPIO1);
    
    if (send_data_to_m3_act) // LED 3
      gpio_set(GPIOB,GPIO7);
    else
      gpio_clear(GPIOB,GPIO7); 

    if (send_data_to_s2_act) // LED 4
      gpio_set(GPIOB,GPIO5);
    else
      gpio_clear(GPIOB,GPIO5);

    if (send_data_to_midi_out_act) // LED 5
      gpio_set(GPIOC,GPIO14);
    else
      gpio_clear(GPIOC,GPIO14);

    //
    //
    // 

    read_data_from_m3_act = 0;
    read_data_from_midi_in_act = 0;
    send_data_to_m3_act = 0;
    send_data_to_midi_out_act = 0;
    send_data_to_s2_act = 0; 

  }

  /*
  while (1) { 
    __asm__("nop");
    } */
  
  return 0;
  
}
