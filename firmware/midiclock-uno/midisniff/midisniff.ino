/* Throwaway MIDI sniffer: reports what is actually arriving, once a
 * second, so "sends clock but no Start" can be told apart from
 * "nothing connected". Counts are per interval, not cumulative. */

unsigned long nF8, nFA, nFB, nFC, nFE, nOther, nTotal;
unsigned long grandTotal = 0;
uint8_t  sample[24];
uint8_t  nsample = 0;
bool     dumped = false;
unsigned long lastReport = 0;

void setup() {
  Serial.begin(31250);
  pinMode(13, OUTPUT);
  delay(200);
  Serial.println(F("SNIFF-READY"));
}

void loop() {
  while (Serial.available()) {
    uint8_t b = Serial.read();
    nTotal++; grandTotal++;
    if (nsample < sizeof(sample)) sample[nsample++] = b;
    switch (b) {
      case 0xF8: nF8++;  digitalWrite(13, (nF8 & 1) ? HIGH : LOW); break;
      case 0xFA: nFA++;  break;
      case 0xFB: nFB++;  break;
      case 0xFC: nFC++;  break;
      case 0xFE: nFE++;  break;
      default:   nOther++; break;
    }
  }

  if (millis() - lastReport >= 1000) {
    lastReport = millis();
    if (nTotal) {
      Serial.print(F("F8=")); Serial.print(nF8);
      Serial.print(F(" FA=")); Serial.print(nFA);
      Serial.print(F(" FB=")); Serial.print(nFB);
      Serial.print(F(" FC=")); Serial.print(nFC);
      Serial.print(F(" FE=")); Serial.print(nFE);
      Serial.print(F(" other=")); Serial.print(nOther);
      Serial.print(F(" total=")); Serial.print(nTotal);
      if (nF8) { Serial.print(F("  -> ")); Serial.print(nF8 * 60.0 / 24.0, 1); Serial.print(F(" BPM")); }
      Serial.println();
      if (!dumped && nsample) {
        dumped = true;
        Serial.print(F("first bytes:"));
        for (uint8_t i = 0; i < nsample; i++) {
          Serial.print(' ');
          if (sample[i] < 16) Serial.print('0');
          Serial.print(sample[i], HEX);
        }
        Serial.println();
      }
    } else {
      Serial.println(F("(silence)"));
    }
    nF8 = nFA = nFB = nFC = nFE = nOther = nTotal = 0;
  }
}
