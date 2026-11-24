// Run from the repo root: QT_QPA_PLATFORM=offscreen /usr/lib/qt6/bin/qmltestrunner -input quickshell/tests
import QtQuick
import QtTest
import "../.config/quickshell/services/logic.js" as Logic

TestCase {
    name: "BarLogic"

    readonly property string stat1: "cpu  100 0 100 700 100 0 0 0 0 0\ncpu0 50 0 50 350 50 0 0 0 0 0\n"
    readonly property string stat2: "cpu  160 0 140 760 140 0 0 0 0 0\ncpu0 80 0 70 380 70 0 0 0 0 0\n"

    function test_cpu_percent_from_two_samples() {
        // busy +100 (user 60, system 40); idle+iowait +100: half busy.
        compare(Logic.cpuPercent(Logic.cpuSample(stat1), Logic.cpuSample(stat2)), 50);
    }

    function test_cpu_percent_with_no_elapsed_time_is_zero() {
        compare(Logic.cpuPercent(Logic.cpuSample(stat1), Logic.cpuSample(stat1)), 0);
    }

    function test_average_of_the_last_samples() {
        compare(Logic.average([90, 100, 95]), 95);
        compare(Logic.average([]), 0);
    }

    function test_memory_from_meminfo() {
        const info = Logic.memory("MemTotal:       32000000 kB\nMemFree:  1000 kB\nMemAvailable:   8000000 kB\n");
        compare(info.percent, 75);
        compare(info.usedGiB.toFixed(1), "22.9");
        compare(info.totalGiB.toFixed(1), "30.5");
    }

    function test_levels_at_and_below_each_threshold() {
        compare(Logic.level("cpu", 79), "normal");
        compare(Logic.level("cpu", 80), "warning");
        compare(Logic.level("cpu", 94), "warning");
        compare(Logic.level("cpu", 95), "critical");
        compare(Logic.level("memory", 89), "warning");
        compare(Logic.level("memory", 90), "critical");
        compare(Logic.level("temperature", 79.9), "normal");
        compare(Logic.level("temperature", 90), "critical");
    }

    function test_temperature_sensor_is_found_by_name_and_label() {
        const sensors = [
            {
                path: "/sys/class/hwmon/hwmon0",
                name: "acpitz",
                labels: {}
            },
            {
                path: "/sys/class/hwmon/hwmon5",
                name: "kraken2023",
                labels: {
                    temp1: "Coolant temp"
                }
            },
            {
                path: "/sys/class/hwmon/hwmon6",
                name: "coretemp",
                labels: {
                    temp1: "Package id 0",
                    temp2: "Core 0"
                }
            }
        ];
        compare(Logic.cpuTemperatureInput(sensors), "/sys/class/hwmon/hwmon6/temp1_input");
        compare(Logic.cpuTemperatureInput([sensors[0]]), "");
    }

    function test_volume_icons() {
        compare(Logic.volumeIcon(0.5, true), "\u{f075f}");
        compare(Logic.volumeIcon(0, false), "\u{f0581}");
        compare(Logic.volumeIcon(0.2, false), "\u{f057f}");
        compare(Logic.volumeIcon(0.5, false), "\u{f0580}");
        compare(Logic.volumeIcon(0.9, false), "\u{f057e}");
    }

    function test_media_label() {
        compare(Logic.mediaLabel("Song", "Artist", 28), "Song – Artist");
        compare(Logic.mediaLabel("Song", "", 28), "Song");
        compare(Logic.mediaLabel("", "", 28), "");
        compare(Logic.mediaLabel("A very long song title indeed", "Someone", 20), "A very long song tit…");
    }

    function test_iso_week_numbers() {
        compare(Logic.isoWeek(new Date(2026, 0, 1)), 1);   // Thursday
        compare(Logic.isoWeek(new Date(2027, 0, 1)), 53);  // Friday: week 53 of 2026
        compare(Logic.isoWeek(new Date(2026, 10, 24)), 48);
    }

    function test_calendar_starts_on_monday_for_every_first_weekday() {
        // Months of 2026 cover every weekday as the first day.
        for (let month = 0; month < 12; month++) {
            const weeks = Logic.calendar(2026, month);
            const first = weeks[0].days;
            compare(first.length, 7);
            compare(first[0].date.getDay(), 1, `month ${month} starts on Monday`);
            const inMonth = weeks.reduce((all, w) => all.concat(w.days), []).filter(d => d.inMonth);
            compare(inMonth.length, new Date(2026, month + 1, 0).getDate());
            compare(inMonth[0].day, 1);
            verify(weeks.length >= 4 && weeks.length <= 6);
        }
        compare(Logic.calendar(2026, 10)[0].week, 44);  // November 2026 starts on a Sunday
    }

    function test_workspace_dots_for_one_monitor() {
        const workspaces = [
            {
                id: 3,
                monitor: "DP-4"
            },
            {
                id: 1,
                monitor: "DP-4"
            },
            {
                id: -98,
                monitor: "DP-4"
            },
            {
                id: 2,
                monitor: "DP-3"
            },
            {
                id: 10,
                monitor: "DP-4"
            }
        ];
        compare(Logic.workspaceIds(workspaces, "DP-4"), [1, 3, 10]);
        compare(Logic.workspaceIds(workspaces, "DP-3"), [2]);
    }

    function test_systemctl_show_parsing() {
        const show = Logic.parseShow("Result=success\nExecMainExitTimestamp=@1764000000\nEmpty=\n");
        compare(show.Result, "success");
        compare(show.ExecMainExitTimestamp, "@1764000000");
        compare(show.Empty, "");
    }

    function test_backup_problems() {
        const now = 1764000000;
        compare(Logic.backupProblems({
            Result: "success",
            ExecMainExitTimestamp: `@${now - 3600}`
        }, now), []);
        const overdue = Logic.backupProblems({
            Result: "success",
            ExecMainExitTimestamp: `@${now - 4 * 3600}`
        }, now);
        compare(overdue.length, 1);
        compare(overdue[0].severity, "warning");
        verify(overdue[0].title.indexOf("overdue") >= 0);
        const failed = Logic.backupProblems({
            Result: "exit-code",
            ExecMainExitTimestamp: `@${now - 600}`
        }, now);
        compare(failed[0].severity, "critical");
        // Never ran this boot: no timestamp, nothing to report yet.
        compare(Logic.backupProblems({
            Result: "success",
            ExecMainExitTimestamp: ""
        }, now), []);
    }

    function test_tailscale_problems() {
        compare(Logic.tailscaleProblems('{"BackendState": "Running"}'), []);
        compare(Logic.tailscaleProblems('{"BackendState": "Stopped"}')[0].severity, "warning");
        compare(Logic.tailscaleProblems("not json")[0].severity, "warning");
    }

    function test_failed_units() {
        compare(Logic.failedUnitProblems("", "system"), []);
        const problems = Logic.failedUnitProblems("foo.service loaded failed failed Foo\nbar.timer loaded failed failed Bar\n", "user");
        compare(problems.length, 2);
        compare(problems[0].title, "foo.service failed");
        verify(problems[0].detail.indexOf("systemctl --user status foo.service") >= 0);
    }

    function test_worst_severity() {
        compare(Logic.worst([]), "");
        compare(Logic.worst([
            {
                severity: "warning"
            }
        ]), "warning");
        compare(Logic.worst([
            {
                severity: "warning"
            },
            {
                severity: "critical"
            }
        ]), "critical");
    }

    function test_voxtype_status() {
        compare(Logic.dictationState('{"text": "x", "alt": "idle", "class": "idle"}'), "idle");
        compare(Logic.dictationState('{"class": "recording"}'), "recording");
        compare(Logic.dictationState('{"class": "transcribing"}'), "transcribing");
        compare(Logic.dictationState("garbage"), "unknown");
    }
}
