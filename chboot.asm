.386 
.model flat, stdcall 
option casemap:none 
include include\include.inc 
include include\rslib.inc 
include include\i2str.asm 
include include\str2i.asm 
includelib lib\str.lib 
includelib lib\rslib.lib 
.data 
usage_msg                    db "Usage:  chboot <ISO_Image> <File_For_Boot>", 13, 10, 0 
.data? 
CommandLine                  DWORD ? 
imgFilename                  DB  512 dup (?) 
dirFilename                  DB  512 dup (?) 
hFile                        DWORD ? 
pFile                        DWORD ? 
sFile                        DWORD ? 
pRecord                      DWORD ? 
i1                           DWORD ? 
i2                           DWORD ? 
.code 
start: 

call GetCommandLine 
mov dword ptr [CommandLine], eax 

call main 

ret 

main proc 
	enter 0, 0 
	
	mov eax, dword ptr [CommandLine] 
	mov ebx, eax 
	
	call s02 
	call s01 
	call s02 
	
	mov eax, offset imgFilename 
	call StringCopy 
	
	call s01 
	call s02 
	
	mov eax, offset dirFilename 
	call StringCopy 
	
	push dword ptr offset imgFilename 
	call t01 
	
	push dword ptr offset dirFilename 
	call t01 
	
	push dword ptr offset imgFilename 
	call uc 
	
	push dword ptr offset dirFilename 
	call uc 
	
	mov eax, offset imgFilename 
	call StringLength 
	cmp eax, 0 
	jz usage_help 
	
	mov eax, offset dirFilename 
	call StringLength 
	cmp eax, 0 
	jz usage_help 
	
	push dword ptr 2 
	push dword ptr space(SIZEOF OFSTRUCT) 
	push dword ptr offset imgFilename 
	call OpenFile 
	mov dword ptr [hFile], eax 
	
	cmp eax, 0 
	jz err_img_fl 
	cmp eax, -1 
	jz err_img_fl 
	
	push dword ptr 0 
	push dword ptr [hFile] 
	call GetFileSize 
	mov dword ptr [sFile], eax 
	
	push eax 
	push dword ptr 0 
	call GlobalAlloc 
	mov dword ptr [pFile], eax 
	
	cmp eax, 0 
	jz err_mem 
	cmp eax, -1 
	jz err_mem 
	
	push dword ptr 0 
	push dword ptr integer() 
	push dword ptr [sFile] 
	push dword ptr [pFile] 
	push dword ptr [hFile] 
	call ReadFile 
	
	push dword ptr offset dirFilename 
	push dword ptr [pFile] 
	call isoGetFileRecord 
	mov dword ptr [pRecord], eax 
	
	cmp eax, 0 
	jz err_dir 
	cmp eax, -1 
	jz err_dir 
	
	mov eax, dword ptr [pFile] 
	mov ebx, eax 
	
	mov al, byte ptr [ebx+32768+2048] 
	cmp al, 0 
	jnz err_boot 
	
	mov eax, dword ptr [ebx+32768+2048+71] 
	mov ecx, eax 
	xor eax, eax 
	mov ax, word ptr [ebx+32768+128] 
	mul ecx 
	mov ecx, eax 
	
	push ecx 
	push ebx 
		mov eax, dword ptr [pRecord] 
		mov ebx, eax 
		
		mov eax, dword ptr [ebx+10] 
		mov ecx, 512 
		div ecx 
		cmp edx, 0 
		jz @F 
			inc eax 
		@@: 
		mov edx, eax 
		
		mov eax, dword ptr [ebx+02] 
	pop ebx 
	pop ecx 
	
	mov word ptr [ebx+ecx+38], dx 
	mov dword ptr [ebx+ecx+40], eax 
	
	mov word ptr [ebx+ecx+102], dx 
	mov dword ptr [ebx+ecx+104], eax 
	
	mov eax, dword ptr [sFile] 
	mov dword ptr [i1], eax 
	
	push dword ptr 0 
	push dword ptr 0 
	push dword ptr 0 
	push dword ptr [hFile] 
	call SetFilePointer 
	
	push dword ptr [hFile] 
	call SetEndOfFile 
	
	push dword ptr 0 
	push dword ptr offset i2 
	push dword ptr [sFile] 
	push dword ptr [pFile] 
	push dword ptr [hFile] 
	call WriteFile 
	
	mov eax, dword ptr [i1] 
	cmp eax, dword ptr [i2] 
	jnz err_write_file 
	
	jmp finish 
	
	usage_help: 
	push dword ptr offset usage_msg 
	call StdOut 
	jmp finish 
	
	err_img_fl: 
	push dword ptr string("Could not open image file ", 13, 10) 
	call StdOut 
	push dword ptr offset imgFilename 
	call StdOut 
	jmp finish 
	
	err_mem: 
	push dword ptr string("Could not allocate memory. ", 13, 10) 
	call StdOut 
	jmp finish 
	
	err_dir: 
	push dword ptr string("Could not find file ") 
	call StdOut 
	push dword ptr offset dirFilename 
	call StdOut 
	push dword ptr string(" on ISO image ") 
	call StdOut 
	push dword ptr offset imgFilename 
	call StdOut 
	push dword ptr string(13, 10) 
	call StdOut 
	
	err_boot: 
	push dword ptr string("Boot record not found. ", 13, 10) 
	call StdOut 
	jmp finish 
	
	err_write_file: 
	push dword ptr string("Error writing to file ", 13, 10) 
	call StdOut 
	push dword ptr offset imgFilename 
	call StdOut 
	push dword ptr string(13, 10) 
	call StdOut 
	
	finish: 
	
	push dword ptr [hFile] 
	call CloseHandle 
	
	push dword ptr [pFile] 
	call GlobalFree 
	
	leave 
	ret 
main endp 

t01 proc 
	enter 0, 0 
	
	mov eax, dword ptr [ebp+8] 
	mov ebx, eax 
	
	lp1: 
		mov al, byte ptr [ebx] 
		cmp al, 32 
		jz lp1s 
		cmp al, 9 
		jz lp1s 
		cmp al, 13 
		jz lp1s 
		cmp al, 10 
		jz lp1s 
		cmp al, 0 
		jz lp1s 
		
		inc ebx 
		jmp lp1 
	lp1s: 
	mov byte ptr [ebx], 0 
	
	leave 
	ret 4 
t01 endp 

s01 proc 
	enter 0, 0 
	
	lp1: 
		mov al, byte ptr [ebx] 
		cmp al, 32 
		jz lp1s 
		cmp al, 10 
		jz lp1s 
		cmp al, 0 
		jz lp1s 
		
		inc ebx 
		jmp lp1 
	lp1s: 
	
	leave 
	ret 
s01 endp 

s02 proc 
	enter 0, 0 
	
	lp1: 
		mov al, byte ptr [ebx] 
		cmp al, 32 
		jz lp1o 
		cmp al, 9 
		jz lp1o 
		
		jmp lp1s 
		
	lp1o: 
		inc ebx 
		jmp lp1 
	lp1s: 
	
	leave 
	ret 
s02 endp 

b_swap proc 
	enter 4, 0 
	pusha 
	
	mov cx, ax 
	shr eax, 16 
	xchg al, ah 
	xchg cl, ch 
	shl ecx, 16 
	mov cx, ax 
	mov eax, ecx 
	
	mov dword ptr [ebp-4], eax 
	
	popa 
	mov eax, dword ptr [ebp-4] 
	leave 
	ret 
b_swap endp 

uc proc 
	enter 0, 0 
	
	mov eax, dword ptr [ebp+8] 
	
	mov ebx, eax 
	lp2: 
		mov al, byte ptr [ebx] 
		cmp al, 97 
		jl lp2o 
		cmp al, 97 + 26 
		jnl lp2o 
		sub al, 32 
		mov byte ptr [ebx], al 
	lp2o: 
		cmp al, 0 
		jz lp2s 
		inc ebx 
		jmp lp2 
	lp2s: 
	
	leave 
	ret 4 
uc endp 

strcmp proc 
	enter 4, 0 
	pusha 
	
	mov edx, ebx 
	mov ebx, eax 
	
	xor eax, eax 
	lp1: 
		mov al, byte ptr [ebx] 
		cmp al, 0 
		jz lp1s 
		sub al, byte ptr [edx] 
		jnz lp1s 
		
		inc ebx 
		inc edx 
		jmp lp1 
	lp1s: 
	
	mov dword ptr [ebp-4], eax 
	
	popa 
	mov eax, dword ptr [ebp-4] 
	leave 
	ret 
strcmp endp 

isoGetFileRecord proc 
	enter 8, 0 
	
	mov eax, dword ptr [ebp+8] 
	mov ebx, eax 
	
	mov al, byte ptr [ebx+32768+00] 
	cmp al, 1 
	jnz err_img 
	
	cmp byte ptr [ebx+32768+01], "C" 
	jnz err_img 
	cmp byte ptr [ebx+32768+02], "D" 
	jnz err_img 
	cmp byte ptr [ebx+32768+03], "0" 
	jnz err_img 
	cmp byte ptr [ebx+32768+04], "0" 
	jnz err_img 
	cmp byte ptr [ebx+32768+05], "1" 
	jnz err_img 
	
	xor eax, eax 
	mov ax, word ptr [ebx+32768+128] 
	mov dword ptr [ebp-4], eax 
	
	mov ecx, 32768 
	add ecx, 156 
	
	mov eax, dword ptr [ebx+ecx+10] 
	add eax, ebx 
	mov dword ptr [ebp-8], eax 
	
	mov eax, dword ptr [ebx+ecx+02] 
	mov ecx, eax 
	mov eax, dword ptr [ebp-4] 
	mul ecx 
	mov ecx, eax 
	
	add dword ptr [ebp-8], eax 
	
	add eax, dword ptr [ebp+8] 
	mov ebx, eax 
	
	xor edx, edx 
	
	lp1: 
		mov eax, dword ptr [ebp-08] 
		cmp ebx, eax 
		jnl lp1s 
		
		mov edx, ebx 
		add ebx, 33 
		mov eax, dword ptr [ebp+12] 
		call strcmp 
		cmp eax, 0 
		jz lp1s 
		
		mov ebx, edx 
		xor eax, eax 
		xor edx, edx 
		mov al, byte ptr [ebx] 
		add ebx, eax 
		cmp eax, 0 
		jnz lp1 
	lp1s: 
	
	jmp finish 
	
	err_img: 
	mov edx, -1 
	
	finish: 
	mov eax, edx 
	
	leave 
	ret 8 
isoGetFileRecord endp 

isoScanForRecord proc 
	enter 0, 0 
	
	mov eax, dword ptr [ebp+8] 
	mov ebx, eax 
	
	xor edx, edx 
	lp1: 
		mov eax, dword ptr [ebp-08] 
		cmp ebx, eax 
		jnl lp1s 
		
		mov edx, ebx 
		add ebx, 33 
		mov eax, dword ptr [ebp+12] 
		call strcmp 
		cmp eax, 0 
		jz lp1s 
		
		mov ebx, edx 
		xor eax, eax 
		xor edx, edx 
		mov al, byte ptr [ebx] 
		add ebx, eax 
		cmp eax, 0 
		jnz lp1 
	lp1s: 
	
	cmp edx, 0 
	jnz @F 
		mov edx, ebx 
	@@: 
	mov eax, edx 
	
	leave 
	ret 8 
isoScanForRecord endp 

end start 