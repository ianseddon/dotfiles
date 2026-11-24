.pragma library

// Pure functions behind the bar's data services and widgets, tested with
// qmltestrunner (quickshell/tests/tst_bar.qml). No Quickshell types here.

// --- System stats ---------------------------------------------------------

// Yellow and red thresholds per reading (docs/desktop-shell/SPEC-bar.md).
const thresholds = {
    cpu: [80, 95],
    memory: [80, 90],
    temperature: [80, 90]
};

// {busy, total} jiffies from /proc/stat's aggregate "cpu" line.
function cpuSample(statText) {
    const line = statText.split("\n").find(l => l.startsWith("cpu "));
    if (!line)
        return { busy: 0, total: 0 };
    const fields = line.trim().split(/\s+/).slice(1).map(Number);
    const idle = fields[3] + (fields[4] || 0); // idle + iowait
    const total = fields.reduce((sum, value) => sum + value, 0);
    return { busy: total - idle, total: total };
}

function cpuPercent(previous, current) {
    const total = current.total - previous.total;
    if (total <= 0)
        return 0;
    return Math.round(100 * (current.busy - previous.busy) / total);
}

function average(values) {
    if (values.length === 0)
        return 0;
    return Math.round(values.reduce((sum, value) => sum + value, 0) / values.length);
}

// {percent, usedGiB, totalGiB} from /proc/meminfo: used = total - available.
function memory(meminfoText) {
    const field = name => {
        const match = meminfoText.match(new RegExp(`^${name}:\\s+(\\d+) kB`, "m"));
        return match ? Number(match[1]) : 0;
    };
    const total = field("MemTotal");
    const used = total - field("MemAvailable");
    const kibPerGib = 1024 * 1024;
    return {
        percent: total > 0 ? Math.round(100 * used / total) : 0,
        usedGiB: used / kibPerGib,
        totalGiB: total / kibPerGib
    };
}

// "normal", "warning" or "critical" for a reading ("cpu", "memory", "temperature").
function level(reading, value) {
    const [warning, critical] = thresholds[reading];
    if (value >= critical)
        return "critical";
    if (value >= warning)
        return "warning";
    return "normal";
}

// The CPU package temperature input among hwmon sensors, each {path, name,
// labels: {temp1: "Package id 0", ...}}: coretemp (Intel) or k10temp (AMD).
// The hwmon number changes between boots, so it is found by name.
function cpuTemperatureInput(sensors) {
    for (const sensor of sensors) {
        if (sensor.name !== "coretemp" && sensor.name !== "k10temp")
            continue;
        for (const [input, label] of Object.entries(sensor.labels)) {
            if (label === "Package id 0" || label === "Tctl")
                return `${sensor.path}/${input}_input`;
        }
    }
    return "";
}

// --- Volume and media -----------------------------------------------------

// Material Design icons from Symbols Nerd Font.
function volumeIcon(volume, muted) {
    if (muted)
        return "\u{f075f}"; // volume-off
    if (volume <= 0)
        return "\u{f0581}"; // volume-mute (zero, not muted)
    if (volume < 0.34)
        return "\u{f057f}"; // volume-low
    if (volume < 0.67)
        return "\u{f0580}"; // volume-medium
    return "\u{f057e}"; // volume-high
}

function elide(text, max) {
    return text.length > max ? text.slice(0, max) + "…" : text;
}

// "Title – Artist", or just the title; elided after `max` characters.
function mediaLabel(title, artist, max) {
    const label = artist ? `${title} – ${artist}` : title;
    return elide(label, max);
}

// --- Calendar -------------------------------------------------------------

// ISO 8601 week number: weeks start on Monday; week 1 holds the year's first Thursday.
function isoWeek(date) {
    const day = new Date(date.getFullYear(), date.getMonth(), date.getDate());
    const weekday = (day.getDay() + 6) % 7; // Monday = 0
    day.setDate(day.getDate() - weekday + 3); // this week's Thursday
    const firstThursday = new Date(day.getFullYear(), 0, 4);
    const firstWeekday = (firstThursday.getDay() + 6) % 7;
    firstThursday.setDate(firstThursday.getDate() - firstWeekday + 3);
    return 1 + Math.round((day - firstThursday) / (7 * 24 * 3600 * 1000));
}

// The weeks shown for a month: [{week, days: [{date, day, inMonth}] x 7}], Monday first.
function calendar(year, month) {
    const first = new Date(year, month, 1);
    const start = new Date(year, month, 1 - (first.getDay() + 6) % 7);
    const last = new Date(year, month + 1, 0);
    const weeks = [];
    for (const day = new Date(start); day <= last || (day.getDay() + 6) % 7 !== 0; ) {
        if ((day.getDay() + 6) % 7 === 0)
            weeks.push({ week: isoWeek(day), days: [] });
        weeks[weeks.length - 1].days.push({
            date: new Date(day),
            day: day.getDate(),
            inMonth: day.getMonth() === month
        });
        day.setDate(day.getDate() + 1);
    }
    return weeks;
}

// --- Workspaces -----------------------------------------------------------

// Normal (positive) workspace ids on one monitor, in order. Special workspaces
// have negative ids.
function workspaceIds(workspaces, monitorName) {
    return workspaces.filter(w => w.id > 0 && w.monitor === monitorName).map(w => w.id).sort((a, b) => a - b);
}

// --- Health ---------------------------------------------------------------

// `systemctl show -p A -p B` output as {A: "...", B: "..."}.
function parseShow(text) {
    const values = {};
    for (const line of text.split("\n")) {
        const at = line.indexOf("=");
        if (at > 0)
            values[line.slice(0, at)] = line.slice(at + 1);
    }
    return values;
}

function problem(severity, title, detail) {
    return { severity: severity, title: title, detail: detail };
}

// borgmatic.service, from `systemctl --user show --timestamp=unix -p Result -p ExecMainExitTimestamp`.
// The timer runs hourly, so a last run over 3 hours ago is overdue.
function backupProblems(show, nowSeconds) {
    const stamp = show.ExecMainExitTimestamp || "";
    if (!stamp.startsWith("@"))
        return []; // hasn't run since login
    const ageHours = (nowSeconds - Number(stamp.slice(1))) / 3600;
    if (show.Result !== "success")
        return [problem("critical", "Backup failed", `borgmatic's last run ended with "${show.Result}". See journalctl --user -u borgmatic.`)];
    if (ageHours > 3)
        return [problem("warning", "Backup overdue", `The last backup finished ${Math.floor(ageHours)} hours ago. See systemctl --user status borgmatic.timer.`)];
    return [];
}

// `tailscale status --json`: anything but a running backend is a problem.
function tailscaleProblems(jsonText) {
    let state = "unknown";
    try {
        state = JSON.parse(jsonText).BackendState || "unknown";
    } catch (error) {}
    if (state === "Running")
        return [];
    return [problem("warning", "Tailscale is not connected", `Its state is "${state}". Run tailscale status.`)];
}

// `systemctl [--user] --failed --no-legend --plain` lines: one problem per unit.
function failedUnitProblems(text, scope) {
    const flag = scope === "user" ? "--user " : "";
    return text.split("\n").filter(line => line.trim()).map(line => {
        const unit = line.trim().split(/\s+/)[0];
        return problem("warning", `${unit} failed`, `See systemctl ${flag}status ${unit}.`);
    });
}

// The highest severity among problems: "critical", "warning", or "" for none.
function worst(problems) {
    if (problems.some(p => p.severity === "critical"))
        return "critical";
    return problems.length > 0 ? "warning" : "";
}

// --- Dictation ------------------------------------------------------------

// voxtype's status ("idle", "recording", "transcribing", ...) from one line of
// `voxtype status --follow --format json`.
function dictationState(line) {
    try {
        return JSON.parse(line)["class"] || "unknown";
    } catch (error) {
        return "unknown";
    }
}
