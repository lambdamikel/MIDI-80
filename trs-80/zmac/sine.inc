;	for ($i = 0; $i < 256; $i++) {
;		push(@s, int(sin($i * 2 * 3.1415926 / 256) * 127));
;	}
;	for ($r = 0; $r < 256; $r += 16) {
;		print "\tdb\t";
;		print join(',', @s[$r .. $r + 15]);
;		print "\n";
;	}
sine:
;# !Gperl sine.inc
	db	0,3,6,9,12,15,18,21,24,27,30,33,36,39,42,45
	db	48,51,54,57,59,62,65,67,70,73,75,78,80,82,85,87
	db	89,91,94,96,98,100,102,103,105,107,108,110,112,113,114,116
	db	117,118,119,120,121,122,123,123,124,125,125,126,126,126,126,126
	db	126,126,126,126,126,126,125,125,124,123,123,122,121,120,119,118
	db	117,116,114,113,112,110,108,107,105,103,102,100,98,96,94,91
	db	89,87,85,82,80,78,75,73,70,67,65,62,59,57,54,51
	db	48,45,42,39,36,33,30,27,24,21,18,15,12,9,6,3
	db	0,-3,-6,-9,-12,-15,-18,-21,-24,-27,-30,-33,-36,-39,-42,-45
	db	-48,-51,-54,-57,-59,-62,-65,-67,-70,-73,-75,-78,-80,-82,-85,-87
	db	-89,-91,-94,-96,-98,-100,-102,-103,-105,-107,-108,-110,-112,-113,-114,-116
	db	-117,-118,-119,-120,-121,-122,-123,-123,-124,-125,-125,-126,-126,-126,-126,-126
	db	-126,-126,-126,-126,-126,-126,-125,-125,-124,-123,-123,-122,-121,-120,-119,-118
	db	-117,-116,-114,-113,-112,-110,-108,-107,-105,-103,-102,-100,-98,-96,-94,-91
	db	-89,-87,-85,-82,-80,-78,-75,-73,-70,-67,-65,-62,-59,-57,-54,-51
	db	-48,-45,-42,-39,-36,-33,-30,-27,-24,-21,-18,-15,-12,-9,-6,-3