#include <LiquidCrystal_I2C.h>  
#include "Countimer.h" 
#include <EEPROM.h>

typedef struct {
	int h,m,s;
} Time;

LiquidCrystal_I2C lcd(0x27, 20, 4); 
Countimer Ct;


/* Macros BUTTON */
#define BUTTON_DOWN   A1
#define BUTTON_UP     A2
#define BUTTON_SET    A3
#define BUTTON_MENU   A0
int flag1,flag2 = 0;
int set = 0;
int relay = 5;
int buzzer = 6;
int encoder = 2;

void ep_write(){
	EEPROM.write(1, time.h);
	EEPROM.write(2, time.m);
	EEPROM.write(3, time.s);
}

void ep_read(){
	time.h = EEPROM.read(1);
	time.m = EEPROM.read(2);
	time.s = EEPROM.read(3);
}

void print_time(){
	time.s -= time.s;
	if (time.s < 0){
		time.s = 59;
		time.m -= 1;
	}
	if (time.m < 0){
		time.m = 59;
		time.h -= 1;
	}
}


void setup_lcd(){
	lcd.init();
	lcd.begin(20,4);
	lcd.backlight();
	lcd.clear();
	lcd.setCursor(5,0);
	lcd.print("TEXT 1");
	lcd.setCursor(4,1);
	lcd.print("TEXT 2");
	Ct.setInterval(print_time, 999);
	ep_read();
	delay(1000);
	lcd.clear();
}

void setup(){
	Serial.begin (9600);

	pinMode(BUTTON_UP, INPUT_PULLUP);
	pinMode(BUTTON_DOWN, INPUT_PULLUP);
	pinMode(BUTTON_SET, INPUT_PULLUP);
	pinMode(BUTTON_MENU, INPUT_PULLUP);

	digitalWrite(encoder, HIGH);
	setup_lcd();
}

void button(){
	if (digitalRead (BUTTON_SET) == 1){
		if (flag1 == 0 && flag2 == 0){
			flag1 = 1;
			set += 1;
			switch (set){
				case 1:
					set = 2;
				case 2:
					set = 3;
				default:
					set = 1;
			}
			delay(100);
		}
	} else {
		flag1 = 0;
	}

	if (digitalRead (BUTTON_UP) == 0){
		switch(set){
			case 0:
				Ct.start();
				flag2 = 1;
				break;
			case 1:
				time.s++;
				break;
			case 2:
				time.m++;
				break;
			case 3:
				time.h++;
				break;
		}
		if (time.s > 59){
			time.s = 0;
		}
		if (time.m > 59){
			time.m = 0;
		}
		if (time.m > 5){
			time.h = 0;
		}

		if (set > 0){
			ep_write();
		}
		delay(200); 
	}

	if (digitalRead (BUTTON_DOWN) == 0){
		if (set==0){
			Ct.stop();
			flag2=0;
		}
		if (set == 1)
			time.s--;
		if (set == 2)
			time.m--;
		if (set == 3)
			time.h--;
		if (time.s<0)
			time.s = 59;
		if (time.m < 0)
			time.h = 59;
		if (time.h < 0)
			time.h = 5;

		if (set > 0)
			ep_write();

		delay(200); 
	}

	if (digitalRead (BUTTON_MENU) == 0){
		flag2 = 1;
		ep_read();
		digitalWrite(relay, HIGH);
		Ct.restart();
		Ct.start();
	}
}

void loop(){
	Time time = { 0 };
	Ct.run();
	button();
	lcd.setCursor(0,1);
	if (set == 1)
		lcd.print("Set S");
	else if (set == 2)
		lcd.print("Set M");
	else
		lcd.print("Set H");

	lcd.setCursor(9,1);
	if (time.h <= 9)
		lcd.print("0");
	lcd.print(time.s);
	lcd.print(":");

	if (time.m <= 9)
		lcd.print("0");
	lcd.print(time.m);
	lcd.print(":");

	if (time.s <= 9)
		lcd.print("0");

	lcd.print(time.s);
	lcd.print("   ");

	if (time.s == 0 && time.m == 0 && time.h && flag2==1){
		flag2=0;
		Ct.stop(); 
		digitalWrite(relay, LOW);
		digitalWrite(buzzer, HIGH);
		delay(300);
		digitalWrite(buzzer, LOW);
		delay(200);
		digitalWrite(buzzer, HIGH);
		delay(300);
		digitalWrite(buzzer, LOW);
		delay(200);
		digitalWrite(buzzer, HIGH);
		delay(300);
		digitalWrite(buzzer, LOW);
	}

	if (flag2 == 1)
		digitalWrite(relay, HIGH);
	else
		digitalWrite(relay, LOW);

	delay(1);
}
