const repository = "https://github.com/SMETAHA/love2d-window-kit";

const examples = [
    {
        id: "navigation-lab",
        name: "Navigation lab",
        note: "New gestures in 1.2",
        description:
            "Smooth precision-trackpad scrolling, pinch + two-finger pan, double-tap zoom, long press and touch-sized window controls.",
        controls: [
            "Trackpad scroll",
            "Ctrl + wheel",
            "Pinch + pan",
            "Double tap",
            "Long press",
        ],
        command: "love . --example=navigation-lab",
        source: "examples/navigation_lab.lua",
        ratio: "118 / 76",
    },
    {
        id: "showcase",
        name: "Full showcase",
        note: "Two viewports",
        description:
            "The default project with a fullscreen canvas, a floating window, focus routing and saved viewport state.",
        controls: ["Drag", "Wheel", "Ctrl + wheel", "S save", "L restore"],
        command: "love .",
        source: "main.lua",
        ratio: "4 / 3",
    },
    {
        id: "minimal",
        name: "Minimal setup",
        note: "Start here",
        description:
            "The smallest complete integration, including the LÖVE callback bridge and one scrollable viewport.",
        controls: ["Drag", "Wheel", "Ctrl + wheel", "Arrow keys"],
        command: "love . --minimal",
        source: "examples/minimal.lua",
        ratio: "4 / 3",
    },
    {
        id: "fullscreen-canvas",
        name: "Fullscreen canvas",
        note: "Pan and zoom",
        description:
            "A large editor-style canvas with cursor-centered zoom and visible-range drawing.",
        controls: ["Drag canvas", "Wheel", "Ctrl + wheel", "+ / −"],
        command: "love . --example=fullscreen-canvas",
        source: "examples/fullscreen_canvas.lua",
        ratio: "4 / 3",
    },
    {
        id: "floating-inventory",
        name: "Floating inventory",
        note: "Game UI",
        description:
            "An inventory window above a world viewport. Capture prevents the background from moving during UI gestures.",
        controls: ["Drag title", "Drag slots", "Wheel", "Click to focus"],
        command: "love . --example=floating-inventory",
        source: "examples/floating_inventory.lua",
        ratio: "4 / 3",
    },
    {
        id: "multi-window-dashboard",
        name: "Window dashboard",
        note: "Layers and focus",
        description:
            "Overlapping tools demonstrate deterministic z-order, raise-on-focus and isolated content spaces.",
        controls: ["Click a panel", "Drag title", "Scroll panel", "Arrow keys"],
        command: "love . --example=multi-window-dashboard",
        source: "examples/multi_window_dashboard.lua",
        ratio: "118 / 76",
    },
    {
        id: "themed-scrollbars",
        name: "Themed scrollbars",
        note: "Visual options",
        description:
            "Custom frame, track and thumb colors with hover, paging, minimum thumb size and auto-hide.",
        controls: ["Wheel", "Drag thumb", "Click track", "Wait for fade"],
        command: "love . --example=themed-scrollbars",
        source: "examples/themed_scrollbars.lua",
        ratio: "4 / 3",
    },
    {
        id: "state-callbacks",
        name: "State and callbacks",
        note: "Persistence",
        description:
            "Save and restore a viewport while inspecting the reasons emitted by scroll and zoom callbacks.",
        controls: ["Move viewport", "S save", "L restore", "Watch events"],
        command: "love . --example=state-callbacks",
        source: "examples/state_callbacks.lua",
        ratio: "4 / 3",
    },
    {
        id: "large-map-culling",
        name: "Large map culling",
        note: "20k × 20k",
        description:
            "A huge virtual tile map that converts visible bounds into a small draw range each frame.",
        controls: ["Drag map", "Wheel", "Ctrl + wheel", "Watch tile count"],
        command: "love . --example=large-map-culling",
        source: "examples/large_map_culling.lua",
        ratio: "4 / 3",
    },
    {
        id: "mobile",
        name: "Touch diagnostics",
        note: "DPI and orientation",
        description:
            "A diagnostic scene for logical coordinates, high-DPI rendering, multi-touch ownership and resize behavior.",
        controls: [
            "One-finger pan",
            "Two-finger pinch",
            "Rotate device",
            "Resize browser",
        ],
        command: "love . --mobile-test",
        source: "examples/mobile_test.lua",
        ratio: "4 / 3",
    },
];

const byId = new Map(examples.map((example) => [example.id, example]));
const select = document.querySelector("#example-select");
const frame = document.querySelector("#demo-frame");
const frameWrap = document.querySelector("#demo-frame-wrap");
const nameNode = document.querySelector("#example-name");
const descriptionNode = document.querySelector("#example-description");
const controlsNode = document.querySelector("#example-controls");
const commandNode = document.querySelector("#example-command");
const sourceNode = document.querySelector("#example-source");
const copyButton = document.querySelector("#copy-command");
let activeId;

for (const example of examples) {
    const option = document.createElement("option");
    option.value = example.id;
    option.textContent = `${example.name} — ${example.note}`;
    select.append(option);
}

function demoUrl(id, reload = false) {
    const query = new URLSearchParams({ scenario: id });
    if (reload) query.set("reload", Date.now().toString());
    return `demo/?${query}`;
}

function selectExample(id, updateUrl = false, reload = false) {
    const example = byId.get(id) || examples[0];
    activeId = example.id;
    nameNode.textContent = example.name;
    descriptionNode.textContent = example.description;
    commandNode.textContent = example.command;
    sourceNode.href = `${repository}/blob/main/${example.source}`;
    frameWrap.style.aspectRatio = example.ratio;
    select.value = example.id;
    controlsNode.replaceChildren(
        ...example.controls.map((control) => {
            const item = document.createElement("span");
            item.textContent = control;
            return item;
        }),
    );

    if (reload || !frame.src || !frame.src.includes(`scenario=${example.id}`)) {
        frame.src = demoUrl(example.id, reload);
    }

    if (updateUrl) {
        const url = new URL(location.href);
        url.searchParams.set("example", example.id);
        history.replaceState({ example: example.id }, "", url);
    }
}

select.addEventListener("change", () => selectExample(select.value, true));

document.querySelector("#reload-demo").addEventListener("click", () => {
    selectExample(activeId, false, true);
});

document
    .querySelector("#fullscreen-demo")
    .addEventListener("click", async () => {
        try {
            await frameWrap.requestFullscreen();
        } catch {
            frame.focus();
        }
    });

copyButton.addEventListener("click", async () => {
    const original = copyButton.textContent;
    try {
        await navigator.clipboard.writeText(commandNode.textContent);
        copyButton.textContent = "Copied";
    } catch {
        copyButton.textContent = "Select command";
    }
    window.setTimeout(() => {
        copyButton.textContent = original;
    }, 1400);
});

frame.addEventListener("load", () => frame.contentWindow?.focus());

window.addEventListener("popstate", () => {
    const requested = new URLSearchParams(location.search).get("example");
    selectExample(requested, false);
});

const requested = new URLSearchParams(location.search).get("example");
selectExample(requested, false);
