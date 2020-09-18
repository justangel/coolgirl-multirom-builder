SAVES .rs 4 ; saves locations

save_state:
  ; saving last started game
  jsr enable_prg_ram
  lda #0 ; first SRAM bank
  sta $5005
  ; storing signature
  ldx #0
.signature_loop:
  lda saves_signature, x
  sta SRAM_SIGNATURE, x
  inx
  cpx #8
  bne .signature_loop
  ; storing selected game
  lda SELECTED_GAME
  sta SRAM_LAST_STARTED_GAME
  lda SELECTED_GAME+1
  sta SRAM_LAST_STARTED_GAME+1
  ; storing scrolling state
  lda SCROLL_LINES_TARGET
  sta SRAM_LAST_STARTED_LINE
  lda SCROLL_LINES_TARGET+1
  sta SRAM_LAST_STARTED_LINE+1
  ; storing save ID of last started game
  lda LAST_STARTED_SAVE
  sta SRAM_LAST_STARTED_SAVE 
  jsr disable_prg_ram
  rts
  
load_state:
  ; loading saved state
  jsr enable_prg_ram
  lda #0 ; first SRAM bank
  sta $5005
  ; check for signature
  ldx #0
.signature_loop:
  lda saves_signature, x
  cmp SRAM_SIGNATURE, x
  bne .end
  inx
  cpx #8
  bne .signature_loop
  ; loading last started game
  lda SRAM_LAST_STARTED_GAME
  sta <SELECTED_GAME
  lda SRAM_LAST_STARTED_GAME+1
  sta <SELECTED_GAME+1
  ; check for invalid value
  lda <SELECTED_GAME
  sec
  sbc games_count
  lda <SELECTED_GAME+1
  sbc games_count+1  
  bcs .ovf
  ; loading scrolling state
  lda SRAM_LAST_STARTED_LINE
  sta <SCROLL_LINES_TARGET
  lda SRAM_LAST_STARTED_LINE+1
  sta <SCROLL_LINES_TARGET+1
  ; loading last save ID
  lda SRAM_LAST_STARTED_SAVE
  sta <LAST_STARTED_SAVE
  jmp .end
.ovf:
  ; reset values
  lda #0
  sta <SELECTED_GAME
  sta <SELECTED_GAME+1
  sta <SCROLL_LINES_TARGET
  sta <SCROLL_LINES_TARGET+1
.end:
  jsr disable_prg_ram
  rts
  
load_save:
  ; loading battery backed save for game if any
  pha
  tya
  pha
  txa
  pha
  
  lda LOADER_GAME_SAVE
  beq .done ; game has not battery backed saves
  ; superbank number
  sta LOADER_GAME_SAVE_SUPERBANK
  dec LOADER_GAME_SAVE_SUPERBANK
  lda LOADER_GAME_SAVE_BANK
  ; � �������
  sta $5005
  lda #0
  sta COPY_SOURCE_ADDR
  sta COPY_DEST_ADDR
  lda #$80
  sta COPY_SOURCE_ADDR+1
  lda #$60
  sta COPY_DEST_ADDR+1
  jsr enable_prg_ram
  jsr read_flash
  jsr disable_prg_ram
.done:
  pla
  tax
  pla
  tay
  pla
  rts
  
  ; �� �� �� �����, ������ � �������� �������
save_save:
  pha
  tya
  pha
  txa
  pha
  lda LOADER_GAME_SAVE
  beq .done ; ���� ���� �� ���������� �����, �� ��
  ; ����� ����������
  sta LOADER_GAME_SAVE_SUPERBANK
  dec LOADER_GAME_SAVE_SUPERBANK
  lda LOADER_GAME_SAVE_BANK
  ; � �������
  sta $5005
  lda #0
  sta COPY_SOURCE_ADDR
  sta COPY_DEST_ADDR
  lda #$60
  sta COPY_SOURCE_ADDR+1
  lda #$80
  sta COPY_DEST_ADDR+1
  jsr enable_prg_ram
  jsr write_flash
  jsr disable_prg_ram
.done:
  pla
  tax
  pla
  tay
  pla
  rts

save_all_saves:
  ldx <LAST_STARTED_SAVE
  bne .there_is_save
  jmp .done
.there_is_save:  
  jsr saving_warning_show
  ldx <LAST_STARTED_SAVE
  dex
  txa
  and #%11111100 ; ����� ������� ���������� � ������
  ora #1 ; ���� ����
  sta <LOADER_GAME_SAVE
  lda #0
  sta <LOADER_GAME_SAVE_BANK  
  ; �������� ��� �����
  ldx #3
.load_all_saves:
  ; ���� ��� � ���� ��������� ����������, �� ����������
  lda <LOADER_GAME_SAVE
  cmp <LAST_STARTED_SAVE
  bne .load_all_saves_skip1
  inc <LOADER_GAME_SAVE  
.load_all_saves_skip1:
  ; ���� ��� ������ ����, �� ���� �� �������
  lda <LOADER_GAME_SAVE_BANK
  cmp #2
  bne .load_all_saves_skip2
  inc <LOADER_GAME_SAVE_BANK
.load_all_saves_skip2:
  ; ���������� � ������ - ��� ����� ����������
  lda <LOADER_GAME_SAVE
  ldy <LOADER_GAME_SAVE_BANK
  sta SAVES, y
  jsr load_save
  inc <LOADER_GAME_SAVE  
  inc <LOADER_GAME_SAVE_BANK  
  dex
  bne .load_all_saves  
  ; � �� ������ ����� � ��� ������ ��������� ����������
  ldx <LAST_STARTED_SAVE
  txa
  ldy #2
  sta SAVES, y
  dex ; ���������� ������ �������
  txa
  ora #%00000011
  sta <LOADER_GAME_SAVE_SUPERBANK ; ����� ����������  
  lda #0
  sta $5005 ; ������� ����
  ; ������� ������
  jsr sector_erase
  ; � ������ ���������� ������ ����� �����
  ldy #0
.write:
  lda SAVES, y
  sta <LOADER_GAME_SAVE
  sty <LOADER_GAME_SAVE_BANK
  jsr save_save
  iny
  cpy #4
  bne .write
.done:
  lda #0
  sta <LAST_STARTED_SAVE ; ������� ����������, ��, �� ��� ���� ����� ������� � SRAM
  jsr save_state
  jsr saving_warning_hide
  rts

saves_signature:
  .db 'C','O','O','L','S','A','V','E'  
