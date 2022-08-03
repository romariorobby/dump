#include <LiquidCrystal_I2C.h>  
#include "Countimer.h" 
#include <EEPROM.h>

LiquidCrystal_I2C lcd(0x27, 20, 4);
Countimer tdown;

/* Macros for button */
#define BTN_SET    A3
#define BTN_UP     A2
#define BTN_DOWN   A1
#define BTN_START  A0


void setup() {
	// Some boilerplate...
	Serial.begin (9600);
	pinMode(BTN_SET,   INPUT_PULLUP);
	pinMode(BTN_UP,    INPUT_PULLUP);
	pinMode(BTN_DOWN,  INPUT_PULLUP);
	pinMode(BTN_START, INPUT_PULLUP);
	lcd.init();
	lcd.clear();
}
void print_time(){
	time_s = time_s-1;
	if (time_s < 0) {
		time_s = 59;
		time_m = time_m-1;
	}

	if (time_m < 0) {
		time_m = 59;
		time_h = time_h-1;
	}

}
void loop(){

}
