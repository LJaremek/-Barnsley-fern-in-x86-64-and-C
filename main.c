#include <allegro5/allegro.h>
#include <allegro5/allegro_image.h>
#include <stdio.h>
#include "f.h"


int main()
{
	// ---------------------------------
	// Wczytywanie danych od użytkownika
	// ---------------------------------
	
	int steps, prob1, prob2, prob3, prob4;
	
	printf("[>] Number of steps (recommended 1.000.000): ");
	scanf("%d", &steps);
	if (steps <= 0)
	{
		printf("[-] Number of steps can not be less than 1.\n");
		return 0;
	}
	
	printf("[>] Option 1 probability (recommended 1): ");
	scanf("%d", &prob1);
	
	printf("[>] Option 2 probability (recommended 8): ");
	scanf("%d", &prob2);
	
	printf("[>] Option 3 probability (recommended 15): ");
	scanf("%d", &prob3);
	
	prob4 = 100 - prob1 - prob2 - prob3;
	if (prob4 < 1)
	{
		printf("[-] Option 4 probability can not be less than 1.\n");
		return 0;
	}
	else
	{
		printf("[+] Option 4 probability: %d\n", prob4);
	}
	
	
	
	// -----------------
	// Tworzenie zdjęcia
	// -----------------
	
	f(steps, prob1, prob2, prob3);

	printf("[+] Image ready\n");
	
	
	
	// --------------------
	// Wyswietlanie zdjecia
	// --------------------
	
	al_init();
	al_init_image_addon();

	ALLEGRO_DISPLAY *window = al_create_display(300, 600);
	al_set_window_title(window, "Bernsley-Fern");
	
	ALLEGRO_EVENT_QUEUE *event_queue = al_create_event_queue();
	al_register_event_source(event_queue, al_get_display_event_source(window));

	ALLEGRO_BITMAP *fern_bmp = al_load_bitmap("fern.bmp");
	
	bool done = false;
	while(!done)
	{
		al_draw_scaled_bitmap(fern_bmp, 0, 0, 600, 1200, 0, 0, 300, 600, 0);
		al_flip_display();
		
		ALLEGRO_EVENT events;
		al_wait_for_event(event_queue, &events);		
		if (events.type == ALLEGRO_EVENT_DISPLAY_CLOSE)
		{
			done = true;
		}

	}
	al_destroy_bitmap(fern_bmp);
	al_destroy_display(window);

	return 0;

}

