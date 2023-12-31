/* SPDX-License-Identifier: BSD-3-Clause */
/* Copyright (c) 2022, Unikraft GmbH and The Unikraft Authors.
 * Licensed under the BSD-3-Clause License (the "License").
 * You may not use this file except in compliance with the License.
 */

#include <uk/config.h>
#include <uk/asm.h>
#include <uk/plat/common/lcpu.h>

#include <kvm-x86/lxboot.h>

/**
 * Stack and entry function to use during CPU initialization
 */
.section .bss
.space 4096
lcpu_bootstack:

lcpu_boot_startup_args:
	.quad	0
	.quad	0

/**
 * 64-bit Linux Boot Protocol entry function
 *
 * RSI holds base address of struct lxboot_params. Flat 4GiB CS and DS segments,
 * with ES and SS set to DS. A20 gate enabled. Protected mode enabled, paging
 * enabled with ident mapping for loaded kernel, zero page (i.e., struct
 * lxboot_params) and command line buffer. Interrupts disabled.
 */
.code64
.section .text.64.boot
ENTRY(_lxboot_entry)
	cmpl	$LXBOOT_HDR_HEADER_MAGIC, LXBOOT_HDR_HEADER_OFFSET(%rsi)
	jne	no_lxboot

	/* startup args for boot CPU */
	leaq	lcpu_boot_startup_args(%rip), %rdi
	leaq	lxboot_entry(%rip), %rax
	movq	%rax, LCPU_SARGS_ENTRY_OFFSET(%rdi)
	leaq	lcpu_bootstack(%rip), %rax
	movq	%rax, LCPU_SARGS_STACKP_OFFSET(%rdi)

	leaq	x86_bpt_pml4(%rip), %rax
	movq	%rax, %cr3

	jmp	lcpu_start64

no_lxboot:
	cli
1:
	hlt
	jmp	1b
END(_lxboot_entry)
