#include <netinet/ip.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/socket.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <unistd.h>
#include <stdarg.h>
#include <fcntl.h>

#define DAEMONIZE

#define SERVER_PORT     20037

void write_log(char * fmt, ...) {
    char buff[1024];
    va_list ap;
    int fd;
    int len;

    va_start(ap, fmt);
    len = vsnprintf(buff, 1024, fmt, ap);
    va_end(ap);

    fd = open("/tmp/echod.log", O_WRONLY|O_APPEND|O_CREAT);
    write(fd, buff, len);
    write(fd, "\n", 1);
    close(fd);
}

void handle_request(int fd, struct sockaddr_in *addr, int addrlen) {
    char buff[100];
    ssize_t bytes;

    bytes = read(fd, buff, 200);        /* oops! 100 != 200 ! */

    write_log("[%d] read %d bytes from %s", time(NULL), bytes, inet_ntoa(addr->sin_addr));

    write(fd, buff, bytes);
}

int main(int argc, char **argv) {
    int sockfd;
    int on = 1;
    struct sockaddr_in addr;
    struct sockaddr_in claddr;
    int addrlen = sizeof(claddr);
    int fd;
    int status;

#ifdef DAEMONIZE
    if(fork() == 0) {
        /* child */
        close(0);
        close(1);
        close(2);
        setsid();
    } else {
        _exit(0);
    }
#endif

    if((sockfd = socket(PF_INET, SOCK_STREAM, 0)) < 0) {
        perror("socket");
        exit(-1);
    }

    addr.sin_family      = AF_INET;
    addr.sin_port        = htons(SERVER_PORT);
    addr.sin_addr.s_addr = htonl(INADDR_ANY);

    setsockopt(sockfd, SOL_SOCKET, SO_REUSEADDR, &on, sizeof(on));

    if(bind(sockfd, (struct sockaddr*)&addr, sizeof(addr)) < 0) {
        perror("bind");
        exit(-1);
    }

    if(listen(sockfd, 4) < 0) {
        perror("listen");
        exit(-1);
    }

    while(1) {
        if((fd = accept(sockfd, (struct sockaddr*)&claddr, &addrlen)) < 0) {
            perror("accept");
            exit(-1);
        }
        if(fork() == 0) {
            close(sockfd);
            handle_request(fd, &claddr, addrlen);
            close(fd);
            _exit(0);
        } else {
            close(fd);
            /* reap any zombie children */
            while(waitpid(-1, &status, WNOHANG) > 0)
                /* do nothing */;
        }
    }
}


