#include <errno.h>
#include <limits.h>
#include <mach-o/dyld.h>
#include <spawn.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/wait.h>
#include <unistd.h>

extern char **environ;

#ifndef LAUNCH_BASH
#define LAUNCH_BASH "/bin/bash"
#endif

static void
dialog(const char *msg)
{
    char escaped[2048];
    size_t j = 0;
    escaped[0] = '\0';
    for (size_t i = 0; msg[i] != '\0' && j + 2 < sizeof(escaped); i++) {
        if (msg[i] == '\\' || msg[i] == '"') {
            escaped[j++] = '\\';
        }
        if (msg[i] == '\n') {
            if (j + 2 < sizeof(escaped)) {
                escaped[j++] = '\\';
                escaped[j++] = 'n';
            }
            continue;
        }
        escaped[j++] = msg[i];
    }
    escaped[j] = '\0';

    char cmd[4096];
    snprintf(cmd, sizeof(cmd),
             "/usr/bin/osascript -e 'display dialog \"%s\" with title \"Scrcpy\" "
             "buttons {\"OK\"} default button \"OK\" with icon caution'",
             escaped);
    /* Best-effort; ignore failure (e.g. no GUI). */
    (void)system(cmd);
}

static void
die(const char *msg)
{
    fprintf(stderr, "Scrcpy: %s: %s\n", msg, strerror(errno));
    char buf[512];
    snprintf(buf, sizeof(buf),
             "Scrcpy の起動に失敗しました。%s\n\n"
             "詳しくは ~/Library/Logs/Scrcpy-launcher.log を見てください。",
             msg);
    dialog(buf);
    exit(1);
}

int
main(int argc, char **argv)
{
    (void)argc;
    (void)argv;

    char exe[PATH_MAX];
    uint32_t n = sizeof(exe);
    if (_NSGetExecutablePath(exe, &n) != 0) {
        errno = ENAMETOOLONG;
        die("実行ファイルの場所がわかりません");
    }

    char resolved[PATH_MAX];
    if (realpath(exe, resolved) == NULL) {
        die("実行ファイルのパスを解決できません");
    }

    char *slash = strrchr(resolved, '/');
    if (slash == NULL) {
        errno = EINVAL;
        die("実行ファイルのパスが不正です");
    }
    *slash = '\0';

    char script[PATH_MAX];
    if (snprintf(script, sizeof(script), "%s/../Resources/launch.sh", resolved)
        >= (int)sizeof(script)) {
        errno = ENAMETOOLONG;
        die("launch.sh のパスが長すぎます");
    }

    char script_real[PATH_MAX];
    if (realpath(script, script_real) == NULL) {
        die("launch.sh が見つかりません");
    }

    /*
     * Stay resident as the app's Mach-O executable and posix_spawn the
     * helper script.  Do not exec: replacing this image with bash is what
     * made "bash" appear as a Local Network client.
     */
    char *args[] = { LAUNCH_BASH, script_real, NULL };
    pid_t pid = 0;
    int err = posix_spawn(&pid, LAUNCH_BASH, NULL, NULL, args, environ);
    if (err != 0) {
        errno = err;
        die("ヘルパーを起動できません");
    }

    int status = 0;
    if (waitpid(pid, &status, 0) < 0) {
        die("ヘルパーの終了待ちに失敗しました");
    }
    if (WIFEXITED(status)) {
        return WEXITSTATUS(status);
    }
    if (WIFSIGNALED(status)) {
        return 128 + WTERMSIG(status);
    }
    return 1;
}
