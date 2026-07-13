const translations = {
    en: {
        navDemo: "Live demo",
        navFeatures: "Features",
        navExamples: "Examples",
        navApi: "API",
        heroTitle:
            "Windows inside your game.<br><span>Without a GUI framework.</span>",
        heroLead:
            "A focused toolkit for scrollable viewports, cursor-centered zoom, draggable floating windows, layered input and touch.",
        runDemo: "Run the live demo",
        viewSource: "View source",
        metaApi: "stable API",
        metaExamples: "runnable examples",
        metaChecks: "test scenarios",
        demoKicker: "Compiled from the repository",
        demoTitle: "The real Lua library, running in your browser",
        demoLead:
            "The compatibility build uses WebAssembly and the same modules that ship in the release. Pick a scenario and interact with it.",
        scenarioShowcase: "Showcase",
        scenarioInventory: "Inventory",
        scenarioDashboard: "Dashboard",
        scenarioTheme: "Scrollbars",
        scenarioMap: "Large map",
        scenarioMobile: "Touch",
        wasmRuntime: "LÖVE 11.5 · WebAssembly",
        reload: "Reload",
        fullscreen: "Fullscreen",
        hintWindow: "title bar or content",
        hintScroll: "scroll",
        hintZoom: "zoom at cursor",
        hintKeys: "active window",
        demoNote:
            "First launch downloads about 5 MB of WebAssembly. Later scenarios reuse the browser cache.",
        featuresKicker: "Small surface, complete behavior",
        featuresTitle: "The windowing pieces games actually need",
        featuresLead:
            "Keep rendering in LÖVE. Let the kit handle coordinates, focus, capture and viewport state.",
        featureScrollTitle: "Scrolling that stays owned",
        featureScrollText:
            "Wheel, keyboard, content drag, scrollbar paging and touch are routed only to the focused viewport.",
        featureZoomTitle: "Cursor-centered zoom",
        featureZoomText:
            "Zoom keeps the content point under the cursor stable and clamps cleanly at content boundaries.",
        featureFloatTitle: "Floating windows",
        featureFloatText:
            "Draggable title bars, responsive constraints, themed chrome and independent content spaces.",
        featureStackTitle: "Focus and layers",
        featureStackText:
            "Deterministic z-order, raise-on-focus and mouse or touch capture across overlapping windows.",
        featureTouchTitle: "Touch and high-DPI",
        featureTouchText:
            "Independent multi-touch ownership, orientation changes and consistent DPI coordinate handling.",
        featureStateTitle: "Serializable state",
        featureStateText:
            "Save and restore position, dimensions, scrolling and zoom with reasoned change callbacks.",
        examplesKicker: "Copyable, runnable modules",
        examplesTitle: "Start with a scenario, then keep only what you need",
        examplesLead:
            "Each example is a regular Lua module with the full callback bridge. Run it locally or inspect the exact source from the site.",
        browseExamples: "Browse all example source →",
        exampleMinimal: "Minimal integration",
        exampleInventory: "Floating inventory",
        exampleDashboard: "Multi-window dashboard",
        exampleCulling: "Large-map culling",
        exampleMobile: "Mobile diagnostics",
        ctaKicker: "Ready for a new LÖVE project",
        ctaTitle: "Clone it, run it, shape it into your own UI.",
        downloadRelease: "Download release",
        quickStart: "Quick start",
        poweredBy: "Browser build powered by",
    },
    ru: {
        navDemo: "Демо",
        navFeatures: "Возможности",
        navExamples: "Примеры",
        navApi: "API",
        heroTitle:
            "Окна внутри игры.<br><span>Без громоздкого GUI-фреймворка.</span>",
        heroLead:
            "Компактный набор для прокручиваемых областей, зума под курсором, плавающих окон, слоёв ввода и сенсорного управления.",
        runDemo: "Запустить демо",
        viewSource: "Открыть код",
        metaApi: "стабильный API",
        metaExamples: "готовых примеров",
        metaChecks: "тестовых сценариев",
        demoKicker: "Собрано прямо из репозитория",
        demoTitle: "Настоящая Lua-библиотека работает в браузере",
        demoLead:
            "WebAssembly-сборка использует те же модули, что входят в релиз. Выберите сценарий и попробуйте управление.",
        scenarioShowcase: "Общее демо",
        scenarioInventory: "Инвентарь",
        scenarioDashboard: "Панели",
        scenarioTheme: "Скроллбары",
        scenarioMap: "Большая карта",
        scenarioMobile: "Тач",
        wasmRuntime: "LÖVE 11.5 · WebAssembly",
        reload: "Перезапуск",
        fullscreen: "На весь экран",
        hintWindow: "заголовок или контент",
        hintScroll: "прокрутка",
        hintZoom: "зум под курсором",
        hintKeys: "активное окно",
        demoNote:
            "При первом запуске загрузится около 5 МБ WebAssembly. Остальные сценарии возьмут runtime из кэша браузера.",
        featuresKicker: "Компактный API, законченное поведение",
        featuresTitle: "Именно те оконные механики, которые нужны играм",
        featuresLead:
            "Рендеринг остаётся в LÖVE, а библиотека берёт на себя координаты, фокус, захват ввода и состояние viewport.",
        featureScrollTitle: "Изолированная прокрутка",
        featureScrollText:
            "Колесо, клавиатура, drag-to-scroll, скроллбары и тач направляются только в активную область.",
        featureZoomTitle: "Зум под курсором",
        featureZoomText:
            "Точка контента под курсором остаётся на месте, а границы корректно ограничиваются.",
        featureFloatTitle: "Плавающие окна",
        featureFloatText:
            "Перетаскиваемые заголовки, адаптивные ограничения, темы и независимые области контента.",
        featureStackTitle: "Фокус и слои",
        featureStackText:
            "Предсказуемый z-order, поднятие при фокусе и захват мыши или касаний в перекрывающихся окнах.",
        featureTouchTitle: "Тач и high-DPI",
        featureTouchText:
            "Независимый multi-touch, смена ориентации и согласованные координаты при масштабировании DPI.",
        featureStateTitle: "Сохранение состояния",
        featureStateText:
            "Сохраняйте позицию, размеры, прокрутку и зум; получайте callbacks с причиной изменения.",
        examplesKicker: "Готовые модули для копирования",
        examplesTitle: "Начните со сценария и оставьте только нужное",
        examplesLead:
            "Каждый пример — обычный Lua-модуль с полным мостом callbacks. Его можно запустить локально или изучить прямо с сайта.",
        browseExamples: "Посмотреть исходники всех примеров →",
        exampleMinimal: "Минимальная интеграция",
        exampleInventory: "Плавающий инвентарь",
        exampleDashboard: "Панель с несколькими окнами",
        exampleCulling: "Отсечение большой карты",
        exampleMobile: "Мобильная диагностика",
        ctaKicker: "Готово для нового проекта LÖVE",
        ctaTitle: "Клонируйте, запустите и соберите свой интерфейс.",
        downloadRelease: "Скачать релиз",
        quickStart: "Быстрый старт",
        poweredBy: "Браузерная сборка работает на",
    },
};

const languageButton = document.querySelector("#language-toggle");
const scenarioName = document.querySelector("#scenario-name");
const demoFrame = document.querySelector("#demo-frame");
const demoViewport = document.querySelector("#demo-viewport");
const scenarioTabs = [...document.querySelectorAll(".scenario-tab")];

let language =
    localStorage.getItem("window-kit-language") ||
    (navigator.language.toLowerCase().startsWith("ru") ? "ru" : "en");
let activeScenario = "showcase";

function translate(lang) {
    language = lang;
    document.documentElement.lang = lang;
    document.querySelectorAll("[data-i18n]").forEach((node) => {
        const value = translations[lang][node.dataset.i18n];
        if (value !== undefined) node.innerHTML = value;
    });
    languageButton.textContent = lang === "en" ? "RU" : "EN";
    languageButton.setAttribute(
        "aria-label",
        lang === "en" ? "Switch to Russian" : "Переключить на английский",
    );
    localStorage.setItem("window-kit-language", lang);
    updateScenarioLabel();
}

function updateScenarioLabel() {
    const tab = scenarioTabs.find(
        (item) => item.dataset.scenario === activeScenario,
    );
    if (tab) scenarioName.textContent = tab.textContent;
}

function scenarioUrl(scenario) {
    return scenario === "showcase"
        ? "demo/"
        : `demo/?scenario=${encodeURIComponent(scenario)}`;
}

function selectScenario(tab) {
    activeScenario = tab.dataset.scenario;
    scenarioTabs.forEach((item) => {
        const selected = item === tab;
        item.classList.toggle("active", selected);
        item.setAttribute("aria-selected", String(selected));
    });
    demoViewport.style.aspectRatio = tab.dataset.ratio || "4 / 3";
    demoFrame.src = scenarioUrl(activeScenario);
    updateScenarioLabel();
}

languageButton.addEventListener("click", () =>
    translate(language === "en" ? "ru" : "en"),
);
scenarioTabs.forEach((tab) =>
    tab.addEventListener("click", () => selectScenario(tab)),
);

document.querySelector("#reload-demo").addEventListener("click", () => {
    demoFrame.src = scenarioUrl(activeScenario);
});

document
    .querySelector("#fullscreen-demo")
    .addEventListener("click", async () => {
        try {
            await demoViewport.requestFullscreen();
        } catch (error) {
            console.warn("Fullscreen request was rejected", error);
        }
    });

document.querySelector("#year").textContent = String(new Date().getFullYear());

const revealObserver = new IntersectionObserver(
    (entries, observer) => {
        entries.forEach((entry) => {
            if (entry.isIntersecting) {
                entry.target.classList.add("revealed");
                observer.unobserve(entry.target);
            }
        });
    },
    { threshold: 0.08 },
);

document
    .querySelectorAll("[data-reveal]")
    .forEach((node) => revealObserver.observe(node));
translate(language);
