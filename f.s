; ---------------------
;	Legenda	
; ---------------------
; xmm0 -> aktualny x
; xmm1 -> aktualny y
; xmm2 -> zmienna pomocnicza
; xmm3 -> zmienna pomocnicza
; xmm4 -> tymczasowy x
; xmm5 -> tymczasowy y
;
; r8  -> deskryptor pliku
; r12 -> ilość kroków
; r13 -> prawdopodobieństwo pierwsze
; r14 -> prawdopodobieństwo drugie
; r15 -> prawdopodobieństwo trzecie



; -----------------------------
;	Informacje o pliku	
; -----------------------------
; szerokość: 600
; wysokość:  1200
; foramt:    24 bity
section .data
	Fname	db	'fern.bmp', 0x00	; nazwa pliku + 0x00 (koniec słowa)
	
	bmphead db  0x42,0x4D,0xB6,0xF5,0x20,0x00,0x00,0x00,0x00,0x00,0x36,0x00,0x00,0x00,0x28,0x00,0x00,0x00,0x58,0x02,0x00,0x00,0xB0,0x04,0x00,0x00,0x01,0x00,0x18,0x00,0x00,0x00,0x00,0x00,0x80,0xF5,0x20,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00 ; header



; ------------------------------------
; BMP header:
; 2 pierwsze:	bmp format
; 3 kolejne:	width*3*height+54
; 5 kolejne:	0x00
; 1 kolejny:	0x36
; 3 kolejne:	0x00
; 1 kolejny:	0x28
; 3 kolejne:	0x00
; 4 kolejne:	szerokość
; 4 kolejne:	wysokość
; 3 kolejne:	0x01, 0x00, 0x18
; 4 kolejne:	0x00
; 3 kolejne:	width*3*height
; 17 kolejne:	0x00
; ------------------------------------
; Jak zapisywać do header'a?
;
; 300(dec) = 12C(hex) = 012C(hex) piszemy to jako: 0x2C, 0x01
;
; ------------------------------------



section .bss
	empty_space:	resb 2160000	; szerokość*wysokość*3 (3 kolory na pixel)



%use fp
section .text
global	f



; --------------------------------------------
;	wczytywanie danych od użytkownika	
; --------------------------------------------
f:
	mov	r12, rdi		; r12 = ilość kroków
	mov	r13, rsi		; r13 = prawdopodobieństwo 1
	mov	r14, rdx		; r14 = prawdopodobieństwo 2
	mov	r15, rcx		; r15 = prawdopodobieństwo 3



; -----------------------------
;	otwieranie pliku		
; -----------------------------
open_file:
	mov	rax, 85		; otworz/stworz plik
	mov	rdi, Fname		; zaladuj nazwe pliku

	mov	rsi, 111111111b	; tryb
	syscall

	mov	r8, rax		; zapisz deskryptor pliku do r8


	; Zapisywanie header'a
	mov	rax, 1			; zapisz do pliku
	mov	rdi, r8		; zapisz deskryptor pliku
	mov	rsi, bmphead		; załaduj header
	mov	rdx, 54		; załaduj długość headera / aktualny_pixel
	syscall

	mov	rbx, 600		; licznik_wierszy
	mov	rdx, empty_space	; ilość_pixeli



; -----------------------------
;	Rysowanie tła		
; -----------------------------
NextRow:
	mov	rcx, 600		; licznik_komórek w wierszu



NextCol:
	mov	byte [rdx+0], 0x00	; niebieski
	mov	byte [rdx+1], 0x00	; zielony
	mov	byte [rdx+2], 0x00	; czerwony

	dec	rcx			; licznik_komórek -= 1
	add	rdx, 3			; aktualny_pixel += 3 (1 pixel = 3 kolory)
	cmp	rcx, 0			; jesli licznik_komórek !=  0:
	jne	NextCol		; 	skocz do NextCol

        dec     rbx			; licznik_wierszy -= 1
        cmp     rbx, 0			; jesli licznik_wierszy != 0:
        jne     NextRow		; 	skocz do NextRow



; -----------------------------
;	Rysowanie paproci		
; -----------------------------
	mov	rcx, r12		; licznik_pętli = 100000
	mov	rax, float64(1.0)	; rax = 1.0
	movq	xmm0, rax		; x = 1.0
	movq	xmm1, rax		; y = 1.0

Draw_point:
	dec	rcx			; licznik_pętli -= 1
	cmp	rcx, 0			; jesli licznik_pętli == 0:
	jz	end			; 	skocz do end

	
	movups	xmm2, xmm1		; xmm2 = y
	cvtsd2si rax, xmm2		; rax = int(y)
	add	rax, 100		; y += 100 (przesunięcie o wektor [0, 100])
	imul	rax, 600		; rax *= width
	imul	rax, 3			; rax *= 3 (3 bity na pixel)
	
	movups	xmm3, xmm0		; xmm3 = x
	cvtsd2si rsi, xmm3		; rdi = int(xmm3)
	add	rsi, 300		; rdi += 300 (przesunięcie o wektor [300, 0])
	imul	rsi, 3			; rdi *= 3 (3 bity na pixel)
	
	add	rax, rsi		; rax = int((y+100)*width + x + 100)*3

	cmp	rax, 2160000		; sprawdzanie czy punkt nie wyszedł poza wymiary obrazka
	jge	Next_point		; jeśli wyszedł, to liczymy kolejny punkt

	mov	rdx, empty_space	; rdx = początek obrazka
	add	rdx, rax		; rdx += policzony pixel
	mov	byte [rdx+0], 0x00	;
	mov	byte [rdx+1], 0xFF	; ustaw policzony pixel jako zielony
	mov	byte [rdx+2], 0x00	;



Next_point:
	rdrand	rax			; rax = losowa liczba
	xor	rdx, rdx		; rdx = 0
	mov	rbx, 100		; rbx = 100
	div	rbx			; rdx %= 100
	
	mov	rax, r13
	cmp	rdx, rax		; jesli rdx < 1:
	jl	Option_3		;	skocz do Option_3
	
	mov	rax, r14
	cmp	rdx, rax		; jesli rdx < 8:
	jl	Option_1		;	skocz do Option_2
	
	mov	rax, r15
	cmp	rdx, rax		; jesli rdx < 15:
	jl	Option_2		;	skocz do Option_1



Option_0:
	mov	rax, float64(0.85)	; rax = 0.85
	movq	xmm2, rax		; xmm2 = 0.85
	movups	xmm4, xmm0		; xmm4 = x
	mulsd	xmm4, xmm2		; xmm4 = x*0.85
	mov	rax, float64(0.04)	; rax = 0.04
	movq	xmm2, rax		; xmm2 = 0.04
	movups	xmm3, xmm1		; xmm3 = y
	mulsd	xmm3, xmm2		; xmm3 = y*0.04
	addsd	xmm4, xmm3		; xmm4 += y*0.04

	mov	rax, float64(-0.04)	; rax = -0.04
	movq	xmm2, rax		; xmm2 = -0.04
	movups	xmm3, xmm0		; xmm3 = x
	mulsd	xmm3, xmm2		; xmm3 *= -0.04
	mov	rax, float64(0.85)	; rax = 0.85
	movq	xmm2, rax		; xmm2 = 0.85
	movups	xmm5, xmm1		; xmm5 = y
	mulsd	xmm5, xmm2		; xmm5 = y*0.85
	addsd	xmm5, xmm3		; xmm5 += x*(-0.04)
	mov	rax, float64(160.0)	; rax = 160 ; 128
	movq	xmm2, rax		; xmm2 = 160
	addsd	xmm5, xmm2		; xmm5 += 160

	movups	xmm0, xmm4		; x = x*0.85 + y*0.04
	movups	xmm1, xmm5		; y = x*(-0.04) + y*0.85 + 1.6
	
	jmp	Draw_point		; skocz do Draw_point


Option_1:
	mov	rax, float64(0.20)	; rax = 0.20
	movq	xmm2, rax		; xmm2 = 0.20
	movups	xmm4, xmm0		; xmm4 = x
	mulsd	xmm4, xmm2		; xmm4 = x*0.20
	mov	rax, float64(-0.26)	; rax = -0.26
	movq	xmm2, rax		; xmm2 = -0.26
	movups	xmm3, xmm1		; xmm3 = y
	mulsd	xmm3, xmm2		; xmm3 = y*(-0.26)
	addsd	xmm4, xmm3		; xmm4 += y*(-0.26)

	mov	rax, float64(0.23)	; rax = 0.23
	movq	xmm2, rax		; xmm2 = 0.23
	movups	xmm3, xmm0		; xmm3 = x
	mulsd	xmm3, xmm2		; xmm3 *= 0.23
	mov	rax, float64(0.22)	; rax = 0.22
	movq	xmm2, rax		; xmm2 = 0.22
	movups	xmm5, xmm1		; xmm5 = y
	mulsd	xmm5, xmm2		; xmm5 = y*0.22
	addsd	xmm5, xmm3		; xmm5 += x*(0.22)
	mov	rax, float64(160.0)	; rax = 1.6
	movq	xmm2, rax		; xmm2 = 1.6
	addsd	xmm5, xmm2		; xmm5 += 1.6

	movups	xmm0, xmm4		; x = x*0.20 + y*(-0.26)
	movups	xmm1, xmm5		; y = x*0.23 + y*0.22 + 1.6
	
	jmp	Draw_point		; skocz do Draw_point


Option_2:
	mov	rax, float64(-0.15)	; rax = -0.15
	movq	xmm2, rax		; xmm2 = -0.15
	movups	xmm4, xmm0		; xmm4 = x
	mulsd	xmm4, xmm2		; xmm4 = x*(-0.15)
	mov	rax, float64(0.28)	; rax = 0.28
	movq	xmm2, rax		; xmm2 = 0.28
	movups	xmm3, xmm1		; xmm3 = y
	mulsd	xmm3, xmm2		; xmm3 = y*0.28
	addsd	xmm4, xmm3		; xmm4 += y*0.28

	mov	rax, float64(0.26)	; rax = 0.26
	movq	xmm2, rax		; xmm2 = 0.26
	movups	xmm3, xmm0		; xmm3 = x
	mulsd	xmm3, xmm2		; xmm3 *= 0.26
	mov	rax, float64(0.24)	; rax = 0.24
	movq	xmm2, rax		; xmm2 = 0.24
	movups	xmm5, xmm1		; xmm5 = y
	mulsd	xmm5, xmm2		; xmm5 = y*0.24
	addsd	xmm5, xmm3		; xmm5 += x*(0.24)
	mov	rax, float64(44.0)	; rax = 0.44
	movq	xmm2, rax		; xmm2 = 0.44
	addsd	xmm5, xmm2		; xmm5 += 0.44

	movups	xmm0, xmm4		; x = x*(-0.15) + y*0.28
	movups	xmm1, xmm5		; y = x*0.26 + y*0.24 + 0.44
	
	jmp	Draw_point		; skocz do Draw_point


Option_3:
	subsd	xmm0, xmm0		; x = 0
	
	mov	rax, float64(0.16)	; rax = 0.16
	movq	xmm2, rax		; xmm2 = 0.16
	mulsd	xmm1, xmm2		; y *= 0.16
	
	jmp	Draw_point		; skocz do Draw_point



; -----------------------------
;	zapis do pliku
; -----------------------------
end:
	mov     rax, 1			; zapisywanie plik
	mov     rdi, r8		; ładowanie deskryptora pliku
	mov     rsi, empty_space	; ładowanie adresu buferu do zapisania
	mov     rdx, 2160000		; ładowanie wielkości buferu
	syscall


	mov     rax, 3			; zamykanie pliku
	mov     rdi, r8		; ładowanie deskryptora
	syscall

	ret
	;mov     rax,60			; zamykanie programu
	;syscall

