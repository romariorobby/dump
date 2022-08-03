#include <LiquidCrystal_I2C.h>  
#include "Countimer.h" 
#include <EEPROM.h>

LiquidCrystal_I2C lcd(0x27, 20, 4);
Countimer Ct;

// Just log to console 
#define DEBUG 1

void print_time()
{
  #if DEBUG
  lcd.SetCursor(0,1);
  lcd.print("TIME:");
  lcd.SetCursor(7,1);
  lcd.print(Ct.getCurrentTime());
  #else
  Serial.print("Time:");
  Serial.println(Ct.getCurrentTime());
  #endif // DEBUG
}

void setup_lcd(){
  lcd.init();
  lcd.clear();

}
void complete(){
  digitaWrite(9 ,HIGH);
}

void setup(){
	Serial.begin (9600);

	#if !DEBUG
  pinMode(BUTTON_UP, INPUT_PULLUP);
  pinMode(BUTTON_DOWN, INPUT_PULLUP);
  pinMode(BUTTON_SET, INPUT_PULLUP);
  pinMode(BUTTON_MENU, INPUT_PULLUP);
	#endif
  
	#if !DEBUG
	setup_lcd();
	#else
  Ct.setCounter(0, 0, 10, Ct.COUNT_UP, complete);
	Ct.setInterval(print_time, 1000);
  Serial.println("Hello");
  Serial.println(Ct.getCurrentTime());
	#endif // DEBUG

}

void loop(){
	Ct.run();
	digitalWrite(5, LOW);
}
