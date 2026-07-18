((cssText, artDataUrl, rawConfig, rawMikuSettings = null) => {
  const STATE_KEY = "__CODEX_DREAM_SKIN_STATE__";
  const STYLE_ID = "codex-dream-skin-style";
  const CHROME_ID = "codex-dream-skin-chrome";
  const ROOT_CLASSES = [
    "codex-dream-skin",
    "dream-theme-light",
    "dream-theme-dark",
    "dream-art-wide",
    "dream-art-standard",
    "dream-focus-left",
    "dream-focus-center",
    "dream-focus-right",
    "dream-safe-left",
    "dream-safe-center",
    "dream-safe-right",
    "dream-safe-none",
    "dream-task-ambient",
    "dream-task-banner",
    "dream-task-off",
    "codex-miku-theme",
    "codex-miku-home",
    "codex-miku-task",
    "miku-effect-stars-off",
    "miku-effect-moon-off",
    "miku-effect-city-off",
    "miku-effect-border-off",
    "miku-effect-meteor-off",
    "miku-effects-paused",
  ];
  const ROOT_PROPERTIES = [
    "--dream-art",
    "--dream-art-position",
    "--dream-focus-x",
    "--dream-focus-y",
    "--dream-accent",
    "--dream-accent-ink",
    "--dream-image-luma",
    "--miku-task-opacity",
    "--miku-task-surface-opacity",
  ];
  const HOME_UTILITY_CLASS = "dream-home-utility";
  const MIKU_OWNED_SELECTOR = '[data-codex-miku-owned="true"]';
  const installToken = {};
  let samplingNativeShell = false;
  let observer = null;
  window.__CODEX_DREAM_SKIN_DISABLED__ = false;

  const clamp = (value, min = 0, max = 1) => Math.min(max, Math.max(min, Number(value)));
  const luminance = (red, green, blue) => {
    const linear = [red, green, blue].map((value) => {
      const channel = value / 255;
      return channel <= .04045 ? channel / 12.92 : ((channel + .055) / 1.055) ** 2.4;
    });
    return .2126 * linear[0] + .7152 * linear[1] + .0722 * linear[2];
  };
  const defaultProfile = {
    appearance: "dark",
    accent: [108, 131, 142],
    focusX: .5,
    focusY: .5,
    aspect: 1.6,
    luma: .32,
    safeArea: "center",
  };

  const normalizeConfig = (value) => {
    const config = value && typeof value === "object" ? value : {};
    const art = config.art && typeof config.art === "object" ? config.art : {};
    const hasNumber = (candidate) =>
      (typeof candidate === "number" || (typeof candidate === "string" && candidate.trim() !== "")) &&
      Number.isFinite(Number(candidate));
    const requestedAccent = typeof config?.palette?.accent === "string"
      ? config.palette.accent.trim()
      : "";
    const safeAccent = /^(?:#[\da-f]{3,8}|(?:rgb|hsl|oklch|oklab)\([^;{}]{1,96}\))$/i.test(requestedAccent)
      ? requestedAccent
      : null;
    const appearance = ["auto", "light", "dark"].includes(config.appearance)
      ? config.appearance
      : "auto";
    const safeArea = ["auto", "left", "right", "center", "none"].includes(art.safeArea)
      ? art.safeArea
      : "auto";
    const taskMode = ["auto", "ambient", "banner", "off"].includes(art.taskMode)
      ? art.taskMode
      : "auto";
    const metadataRatio = Number(config?.artMetadata?.ratio);
    return {
      appearance,
      safeArea,
      taskMode,
      focusX: hasNumber(art.focusX) ? clamp(art.focusX) : null,
      focusY: hasNumber(art.focusY) ? clamp(art.focusY) : null,
      accent: safeAccent,
      initialAspect: Number.isFinite(metadataRatio) && metadataRatio > 0 ? metadataRatio : null,
    };
  };

  const MIKU_DEFAULT_SETTINGS = Object.freeze({
    schemaVersion: 1,
    taskOpacity: .30,
    effects: Object.freeze({
      stars: true,
      moonBreathing: true,
      cityLights: true,
      borderFlow: true,
      meteor: true,
      paused: false,
    }),
  });
  const normalizeMikuSettings = (value) => {
    const source = value && typeof value === "object" && !Array.isArray(value) ? value : {};
    const effects = source.effects && typeof source.effects === "object" &&
      !Array.isArray(source.effects) ? source.effects : {};
    const bool = (candidate, fallback) => typeof candidate === "boolean" ? candidate : fallback;
    const opacity = typeof source.taskOpacity === "number" && Number.isFinite(source.taskOpacity)
      ? Math.min(1, Math.max(.05, source.taskOpacity))
      : MIKU_DEFAULT_SETTINGS.taskOpacity;
    return {
      schemaVersion: 1,
      taskOpacity: opacity,
      effects: {
        stars: bool(effects.stars, true),
        moonBreathing: bool(effects.moonBreathing, true),
        cityLights: bool(effects.cityLights, true),
        borderFlow: bool(effects.borderFlow, true),
        meteor: bool(effects.meteor, true),
        paused: bool(effects.paused, false),
      },
    };
  };
  const MIKU_ACTIONS = Object.freeze([
    {
      icon: "⌘",
      label: "探索并理解代码",
      hint: "梳理结构与关键问题",
      prompt: "帮我理解并梳理这个代码库：先说明整体结构、关键模块与运行方式，再列出最值得优先处理的三个问题。",
    },
    {
      icon: "✦",
      label: "构建新功能",
      hint: "从方案到测试落地",
      prompt: "根据我的目标构建一个新功能：先澄清必要约束，给出实现方案，再编码、测试并总结改动。",
    },
    {
      icon: "✓",
      label: "审查代码改动",
      hint: "检查风险与覆盖率",
      prompt: "审查当前改动：重点检查正确性、边界条件、安全性和测试覆盖，并按优先级给出可执行建议。",
    },
    {
      icon: "⚒",
      label: "诊断并修复问题",
      hint: "定位根因并验证修复",
      prompt: "诊断并修复当前问题：先复现并定位根因，再进行最小修改，运行相关测试并说明验证结果。",
    },
  ]);

  const previous = window[STATE_KEY];
  if (previous?.observer) previous.observer.disconnect();
  if (previous?.timer) clearInterval(previous.timer);
  if (previous?.scheduler?.timeout) clearTimeout(previous.scheduler.timeout);
  if (previous?.artUrl) URL.revokeObjectURL(previous.artUrl);
  document.querySelectorAll(MIKU_OWNED_SELECTOR).forEach((node) => node.remove());
  const artUrl = (() => {
    const comma = artDataUrl.indexOf(",");
    const binary = atob(artDataUrl.slice(comma + 1));
    const bytes = new Uint8Array(binary.length);
    for (let index = 0; index < binary.length; index += 1) bytes[index] = binary.charCodeAt(index);
    const mime = /^data:([^;,]+)/.exec(artDataUrl)?.[1] || "image/png";
    return URL.createObjectURL(new Blob([bytes], { type: mime }));
  })();
  const config = normalizeConfig(rawConfig);
  let mikuSettings = normalizeMikuSettings(
    rawMikuSettings ?? window.__CODEX_MIKU_THEME_SETTINGS__?.value,
  );
  const previousMikuRevision = Number(window.__CODEX_MIKU_THEME_SETTINGS__?.revision);
  window.__CODEX_MIKU_THEME_SETTINGS__ = {
    revision: Number.isSafeInteger(previousMikuRevision) && previousMikuRevision >= 0
      ? previousMikuRevision
      : 0,
    value: mikuSettings,
    status: "ready",
  };
  let profile = {
    ...defaultProfile,
    aspect: config.initialAspect ?? defaultProfile.aspect,
  };
  const existingStyle = document.getElementById(STYLE_ID);
  if (existingStyle) {
    existingStyle.textContent = cssText;
    existingStyle.dataset.dreamVersion = "4";
  }

  const analyzeArt = () => new Promise((resolve) => {
    if (typeof Image !== "function") {
      resolve(defaultProfile);
      return;
    }
    const image = new Image();
    image.onload = () => {
      try {
        const width = 48;
        const height = Math.max(12, Math.round(width * image.naturalHeight / image.naturalWidth));
        const canvas = document.createElement("canvas");
        canvas.width = width;
        canvas.height = height;
        const context = canvas.getContext?.("2d", { willReadFrequently: true });
        if (!context) throw new Error("Canvas is unavailable");
        context.drawImage(image, 0, 0, width, height);
        const pixels = context.getImageData(0, 0, width, height).data;
        let count = 0;
        let totalRed = 0;
        let totalGreen = 0;
        let totalBlue = 0;
        let totalBrightness = 0;
        const samples = [];
        const sampleMap = new Array(width * height);
        for (let offset = 0; offset < pixels.length; offset += 4) {
          if (pixels[offset + 3] < 96) continue;
          const red = pixels[offset];
          const green = pixels[offset + 1];
          const blue = pixels[offset + 2];
          const light = (.2126 * red + .7152 * green + .0722 * blue) / 255;
          const sample = { red, green, blue, light, index: offset / 4 };
          samples.push(sample);
          sampleMap[sample.index] = sample;
          totalRed += red;
          totalGreen += green;
          totalBlue += blue;
          totalBrightness += light;
          count += 1;
        }
        if (!count) throw new Error("Image contains no opaque pixels");
        const average = [totalRed / count, totalGreen / count, totalBlue / count];
        const averageBrightness = totalBrightness / count;
        const information = (start, end) => {
          let total = 0;
          let totalSquared = 0;
          let edges = 0;
          let edgeCount = 0;
          let sampleCount = 0;
          for (let y = 0; y < height; y += 1) {
            for (let x = start; x < end; x += 1) {
              const sample = sampleMap[y * width + x];
              if (!sample) continue;
              total += sample.light;
              totalSquared += sample.light * sample.light;
              sampleCount += 1;
              const previousSample = x > start ? sampleMap[y * width + x - 1] : null;
              const above = y > 0 ? sampleMap[(y - 1) * width + x] : null;
              if (previousSample) { edges += Math.abs(sample.light - previousSample.light); edgeCount += 1; }
              if (above) { edges += Math.abs(sample.light - above.light); edgeCount += 1; }
            }
          }
          const mean = sampleCount ? total / sampleCount : 0;
          const variance = sampleCount ? Math.max(0, totalSquared / sampleCount - mean * mean) : 1;
          return Math.sqrt(variance) * .58 + (edgeCount ? edges / edgeCount : 1) * .42;
        };
        const zoneWidth = Math.max(1, Math.floor(width * .38));
        const leftInformation = information(0, zoneWidth);
        const rightInformation = information(width - zoneWidth, width);
        let safeArea = "center";
        if (leftInformation < rightInformation * .86) safeArea = "left";
        else if (rightInformation < leftInformation * .86) safeArea = "right";
        let focusWeight = 0;
        let focusX = 0;
        let focusY = 0;
        let accentWeight = 0;
        let accent = [0, 0, 0];
        for (const sample of samples) {
          const x = sample.index % width;
          const y = Math.floor(sample.index / width);
          const difference = Math.sqrt(
            (sample.red - average[0]) ** 2 +
            (sample.green - average[1]) ** 2 +
            (sample.blue - average[2]) ** 2,
          ) / 441.7;
          const saliency = .03 + difference ** 1.35;
          focusX += (x / Math.max(1, width - 1)) * saliency;
          focusY += (y / Math.max(1, height - 1)) * saliency;
          focusWeight += saliency;
          const max = Math.max(sample.red, sample.green, sample.blue);
          const min = Math.min(sample.red, sample.green, sample.blue);
          const saturation = max ? (max - min) / max : 0;
          const usableLight = 1 - Math.min(1, Math.abs(sample.light - .46) / .54);
          const weight = saturation ** 2 * (.15 + usableLight);
          accent[0] += sample.red * weight;
          accent[1] += sample.green * weight;
          accent[2] += sample.blue * weight;
          accentWeight += weight;
        }
        const resolvedAccent = accentWeight > 1
          ? accent.map((channel) => Math.round(channel / accentWeight))
          : average.map((channel) => Math.round(channel));
        let resolvedFocusX = clamp(focusX / focusWeight);
        if (safeArea === "left") resolvedFocusX = Math.max(.64, resolvedFocusX);
        if (safeArea === "right") resolvedFocusX = Math.min(.36, resolvedFocusX);
        resolve({
          appearance: averageBrightness >= .58 ? "light" : "dark",
          accent: resolvedAccent,
          focusX: resolvedFocusX,
          focusY: clamp(focusY / focusWeight),
          aspect: image.naturalWidth / Math.max(1, image.naturalHeight),
          luma: clamp(averageBrightness),
          safeArea,
        });
      } catch {
        resolve(defaultProfile);
      }
    };
    image.onerror = () => resolve(defaultProfile);
    image.src = artUrl;
  });

  const detectShellAppearance = () => {
    const root = document.documentElement;
    const body = document.body;
    const classes = `${root?.className || ""} ${body?.className || ""}`
      .toLowerCase()
      .replace(/\bdream-theme-(?:dark|light)\b/g, "");
    if (/\b(dark|electron-dark|theme-dark|appearance-dark)\b/.test(classes)) return "dark";
    if (/\b(light|electron-light|theme-light|appearance-light)\b/.test(classes)) return "light";

    const dataTheme = (
      root?.getAttribute?.("data-theme") ||
      root?.getAttribute?.("data-appearance") ||
      root?.getAttribute?.("data-color-mode") ||
      body?.getAttribute?.("data-theme") ||
      body?.getAttribute?.("data-appearance") ||
      ""
    ).toLowerCase();
    if (dataTheme.includes("dark")) return "dark";
    if (dataTheme.includes("light")) return "light";

    try {
      const hadSkin = root?.classList?.contains?.("codex-dream-skin");
      const savedSkinClasses = hadSkin
        ? ROOT_CLASSES.filter((className) => root.classList.contains(className))
        : [];
      samplingNativeShell = true;
      if (hadSkin) root.classList.remove(...ROOT_CLASSES);
      try {
        const colorScheme = getComputedStyle(root).colorScheme || "";
        if (colorScheme.includes("dark") && !colorScheme.includes("light")) return "dark";
        if (colorScheme.includes("light") && !colorScheme.includes("dark")) return "light";
      } finally {
        if (hadSkin) root.classList.add(...savedSkinClasses);
        observer?.takeRecords?.();
        samplingNativeShell = false;
      }
    } catch {
      samplingNativeShell = false;
    }
    try {
      return window.matchMedia("(prefers-color-scheme: dark)").matches ? "dark" : "light";
    } catch {}
    return "light";
  };

  const clearSkinDom = () => {
    const root = document.documentElement;
    root?.classList.remove(...ROOT_CLASSES);
    for (const property of ROOT_PROPERTIES) root?.style.removeProperty(property);
    document.querySelectorAll(".dream-home").forEach((node) => node.classList.remove("dream-home"));
    document.querySelectorAll(".dream-task").forEach((node) => node.classList.remove("dream-task"));
    document.querySelectorAll(".dream-home-shell").forEach((node) => node.classList.remove("dream-home-shell"));
    document.querySelectorAll(`.${HOME_UTILITY_CLASS}`).forEach((node) => node.classList.remove(HOME_UTILITY_CLASS));
    document.querySelectorAll(MIKU_OWNED_SELECTOR).forEach((node) => node.remove());
    root?.removeAttribute?.("data-miku-appearance");
    document.getElementById(STYLE_ID)?.remove();
    document.getElementById(CHROME_ID)?.remove();
  };

  const applyProfile = (root) => {
    const focusX = config.focusX ?? profile.focusX;
    const focusY = config.focusY ?? profile.focusY;
    const appearance = config.appearance === "auto" ? detectShellAppearance() : config.appearance;
    const focus = focusX < .4 ? "left" : focusX > .6 ? "right" : "center";
    const safeArea = config.safeArea === "auto" ? (profile.safeArea ||
      (focus === "left" ? "right" : focus === "right" ? "left" : "center")) : config.safeArea;
    const taskMode = config.taskMode === "auto"
      ? profile.aspect >= 2.25 ? "banner" : "ambient"
      : config.taskMode;
    const accent = config.accent || `rgb(${profile.accent.join(" ")})`;
    const accentInk = luminance(...profile.accent) > .42 ? "rgb(26 24 28)" : "rgb(250 248 251)";
    root.setAttribute?.("data-miku-appearance", appearance);
    root.classList.toggle("dream-theme-light", appearance === "light");
    root.classList.toggle("dream-theme-dark", appearance === "dark");
    root.classList.toggle("dream-art-wide", profile.aspect >= 1.75);
    root.classList.toggle("dream-art-standard", profile.aspect < 1.75);
    for (const value of ["left", "center", "right"]) {
      root.classList.toggle(`dream-focus-${value}`, focus === value);
    }
    for (const value of ["left", "center", "right", "none"]) {
      root.classList.toggle(`dream-safe-${value}`, safeArea === value);
    }
    for (const value of ["ambient", "banner", "off"]) {
      root.classList.toggle(`dream-task-${value}`, taskMode === value);
    }
    root.style.setProperty("--dream-art", `url("${artUrl}")`);
    root.style.setProperty("--dream-art-position", `${Math.round(focusX * 100)}% ${Math.round(focusY * 100)}%`);
    root.style.setProperty("--dream-focus-x", String(focusX));
    root.style.setProperty("--dream-focus-y", String(focusY));
    root.style.setProperty("--dream-accent", accent);
    root.style.setProperty("--dream-accent-ink", accentInk);
    root.style.setProperty("--dream-image-luma", profile.luma.toFixed(3));
  };

  const createMikuElement = (tagName, className = "", text = "") => {
    const element = document.createElement(tagName);
    if (className) element.className = className;
    if (text) element.textContent = text;
    element.setAttribute?.("data-codex-miku-owned", "true");
    return element;
  };

  const showMikuToast = (message) => {
    if (!document.body || typeof document.body.appendChild !== "function") return;
    document.getElementById("codex-miku-toast")?.remove();
    const toast = createMikuElement("div", "codex-miku-toast", message);
    toast.id = "codex-miku-toast";
    toast.setAttribute?.("role", "status");
    document.body.appendChild(toast);
    setTimeout(() => toast.remove?.(), 2600);
  };

  const findNativeComposer = () => {
    const selectors = [
      'textarea:not([data-codex-miku-owned="true"])',
      '[contenteditable="true"][role="textbox"]:not([data-codex-miku-owned="true"])',
      '[contenteditable="true"]:not([data-codex-miku-owned="true"])',
    ];
    for (const selector of selectors) {
      const candidate = document.querySelector(selector);
      if (!candidate || candidate.closest?.(MIKU_OWNED_SELECTOR)) continue;
      return candidate;
    }
    return null;
  };

  const dispatchComposerEvent = (composer, type) => {
    const event = typeof window.Event === "function"
      ? new window.Event(type, { bubbles: true })
      : { type, bubbles: true };
    composer.dispatchEvent?.(event);
  };

  const setComposerPrompt = (text) => {
    const composer = findNativeComposer();
    if (!composer) {
      showMikuToast("未找到可用的 Codex 输入框，请先进入可输入页面。");
      return false;
    }
    const tagName = String(composer.tagName || "").toUpperCase();
    if (tagName === "TEXTAREA" || tagName === "INPUT") {
      let prototype = Object.getPrototypeOf(composer);
      let valueSetter = null;
      while (prototype && !valueSetter) {
        valueSetter = Object.getOwnPropertyDescriptor(prototype, "value")?.set || null;
        prototype = Object.getPrototypeOf(prototype);
      }
      if (valueSetter) valueSetter.call(composer, text);
      else composer.value = text;
    } else {
      composer.textContent = text;
    }
    dispatchComposerEvent(composer, "input");
    dispatchComposerEvent(composer, "change");
    composer.focus?.();
    showMikuToast("提示词已填入，确认后再由你发送。");
    return true;
  };

  const updateMikuBridge = (value, bumpRevision = false) => {
    const previousRevision = Number(window.__CODEX_MIKU_THEME_SETTINGS__?.revision);
    const revision = Number.isSafeInteger(previousRevision) && previousRevision >= 0
      ? previousRevision + (bumpRevision ? 1 : 0)
      : bumpRevision ? 1 : 0;
    window.__CODEX_MIKU_THEME_SETTINGS__ = {
      revision,
      value,
      status: window.__CODEX_MIKU_THEME_SETTINGS__?.status || "ready",
    };
  };

  const applyMikuSettings = (value, options = {}) => {
    mikuSettings = normalizeMikuSettings(value);
    const root = document.documentElement;
    if (root) {
      root.style.setProperty("--miku-task-opacity", mikuSettings.taskOpacity.toFixed(2));
      root.style.setProperty(
        "--miku-task-surface-opacity",
        `${Math.round((1 - mikuSettings.taskOpacity) * 100)}%`,
      );
      root.classList.toggle("miku-effect-stars-off", !mikuSettings.effects.stars);
      root.classList.toggle("miku-effect-moon-off", !mikuSettings.effects.moonBreathing);
      root.classList.toggle("miku-effect-city-off", !mikuSettings.effects.cityLights);
      root.classList.toggle("miku-effect-border-off", !mikuSettings.effects.borderFlow);
      root.classList.toggle("miku-effect-meteor-off", !mikuSettings.effects.meteor);
      root.classList.toggle("miku-effects-paused", mikuSettings.effects.paused);
    }
    updateMikuBridge(mikuSettings, Boolean(options.bumpRevision));

    const panel = document.getElementById("codex-miku-theme-settings");
    const opacity = panel?.querySelector?.('[data-miku-setting="taskOpacity"]');
    if (opacity && document.activeElement !== opacity) {
      opacity.value = String(Math.round(mikuSettings.taskOpacity * 100));
    }
    for (const key of ["stars", "moonBreathing", "cityLights", "borderFlow", "meteor", "paused"]) {
      const control = panel?.querySelector?.(`[data-miku-setting="${key}"]`);
      if (control) control.checked = mikuSettings.effects[key];
    }
    return mikuSettings;
  };

  const mountMikuHome = (home) => {
    if (!home || typeof home.appendChild !== "function") return null;
    const existing = document.getElementById("codex-miku-home");
    if (existing) return existing;
    const capabilityProbe = document.createElement("div");
    if (typeof capabilityProbe.appendChild !== "function" ||
      typeof capabilityProbe.addEventListener !== "function") return null;

    const hero = createMikuElement("section", "codex-miku-hero");
    hero.id = "codex-miku-home";
    hero.setAttribute("aria-label", "初音未来·月光都市快捷操作");

    const copy = createMikuElement("div", "codex-miku-hero-copy");
    copy.appendChild(createMikuElement("p", "codex-miku-eyebrow", "MIKU MOONLIGHT · CODEX"));
    copy.appendChild(createMikuElement("h1", "codex-miku-hero-title", "我们该构建什么？"));
    copy.appendChild(createMikuElement(
      "p",
      "codex-miku-hero-subtitle",
      "让灵感在月光城市醒来。选择一个入口，把提示词交给原生输入框后再由你确认发送。",
    ));
    hero.appendChild(copy);

    for (const className of [
      "codex-miku-stars",
      "codex-miku-moon-glow",
      "codex-miku-city-lights",
      "codex-miku-border-flow",
      "codex-miku-meteor",
    ]) {
      const decoration = createMikuElement("div", className);
      decoration.setAttribute("aria-hidden", "true");
      hero.appendChild(decoration);
    }

    const grid = createMikuElement("div", "codex-miku-action-grid");
    for (const action of MIKU_ACTIONS) {
      const button = createMikuElement("button", "codex-miku-action-card");
      button.type = "button";
      button.setAttribute("aria-label", action.label);
      button.appendChild(createMikuElement("span", "codex-miku-action-icon", action.icon));
      button.appendChild(createMikuElement("span", "codex-miku-action-label", action.label));
      button.appendChild(createMikuElement("span", "codex-miku-action-hint", action.hint));
      button.addEventListener("click", () => setComposerPrompt(action.prompt));
      grid.appendChild(button);
    }
    hero.appendChild(grid);
    if (typeof home.prepend === "function") home.prepend(hero);
    else home.appendChild(hero);
    return hero;
  };

  const mountMikuSettings = () => {
    if (!document.body || typeof document.body.appendChild !== "function") return null;
    const existing = document.getElementById("codex-miku-theme-settings");
    if (existing) {
      applyMikuSettings(mikuSettings);
      return existing;
    }
    const trigger = createMikuElement("button", "codex-miku-settings-trigger", "✦");
    if (typeof trigger.addEventListener !== "function") return null;
    trigger.id = "codex-miku-settings-trigger";
    trigger.type = "button";
    trigger.setAttribute("aria-label", "打开初音未来主题设置");
    trigger.setAttribute("aria-expanded", "false");

    const panel = createMikuElement("section");
    panel.id = "codex-miku-theme-settings";
    panel.hidden = true;
    panel.appendChild(createMikuElement("strong", "", "初音未来·月光都市"));

    const opacityRow = createMikuElement("div", "codex-miku-opacity-control");
    const opacityLabel = createMikuElement("span", "", "任务背景透明度");
    opacityLabel.id = "codex-miku-opacity-label";
    const stepper = createMikuElement("div", "codex-miku-opacity-stepper");
    const decrement = createMikuElement("button", "codex-miku-opacity-button", "－");
    decrement.type = "button";
    decrement.setAttribute("data-miku-opacity-decrement", "true");
    decrement.setAttribute("aria-label", "降低任务背景透明度");
    const input = createMikuElement("input", "codex-miku-opacity-input");
    input.type = "number";
    input.min = "5";
    input.max = "100";
    input.step = "1";
    input.inputMode = "numeric";
    input.setAttribute("data-miku-setting", "taskOpacity");
    input.setAttribute("aria-labelledby", opacityLabel.id);
    const increment = createMikuElement("button", "codex-miku-opacity-button", "＋");
    increment.type = "button";
    increment.setAttribute("data-miku-opacity-increment", "true");
    increment.setAttribute("aria-label", "提高任务背景透明度");
    stepper.appendChild(decrement);
    stepper.appendChild(input);
    stepper.appendChild(increment);
    opacityRow.appendChild(opacityLabel);
    opacityRow.appendChild(stepper);
    panel.appendChild(opacityRow);

    const toggles = [
      ["stars", "星光"],
      ["moonBreathing", "月光呼吸"],
      ["cityLights", "城市灯光"],
      ["borderFlow", "边框流光"],
      ["meteor", "流星"],
      ["paused", "暂停全部动态"],
    ];
    for (const [key, labelText] of toggles) {
      const row = createMikuElement("label", "codex-miku-setting-row");
      row.appendChild(createMikuElement("span", "", labelText));
      const toggle = createMikuElement("input");
      toggle.type = "checkbox";
      toggle.setAttribute("data-miku-setting", key);
      row.appendChild(toggle);
      panel.appendChild(row);
      toggle.addEventListener("change", () => {
        const next = normalizeMikuSettings(mikuSettings);
        next.effects[key] = Boolean(toggle.checked);
        applyMikuSettings(next, { bumpRevision: true });
      });
    }

    const status = createMikuElement("div", "codex-miku-settings-status");
    status.setAttribute("data-miku-settings-status", "true");
    status.setAttribute("role", "status");
    panel.appendChild(status);
    const reset = createMikuElement("button", "codex-miku-settings-reset", "恢复默认设置");
    reset.type = "button";
    reset.addEventListener("click", () => applyMikuSettings(MIKU_DEFAULT_SETTINGS, { bumpRevision: true }));
    panel.appendChild(reset);

    const currentOpacityPercent = () => Math.round(mikuSettings.taskOpacity * 100);
    const restoreOpacityInput = () => {
      input.value = String(currentOpacityPercent());
    };
    const commitOpacityInput = () => {
      const candidate = Number(input.value);
      if (!Number.isFinite(candidate) || input.value.trim() === "") {
        restoreOpacityInput();
        return false;
      }
      const percent = Math.min(100, Math.max(5, Math.round(candidate)));
      const next = normalizeMikuSettings(mikuSettings);
      next.taskOpacity = percent / 100;
      applyMikuSettings(next, { bumpRevision: true });
      input.value = String(percent);
      return true;
    };
    const stepOpacity = (delta) => {
      const percent = Math.min(100, Math.max(5, currentOpacityPercent() + delta));
      input.value = String(percent);
      commitOpacityInput();
      input.focus?.();
    };
    decrement.addEventListener("click", () => stepOpacity(-1));
    increment.addEventListener("click", () => stepOpacity(1));
    input.addEventListener("change", commitOpacityInput);
    input.addEventListener("keydown", (event) => {
      if (event.key === "Enter") {
        event.preventDefault?.();
        commitOpacityInput();
        input.focus?.();
      } else if (event.key === "Escape") {
        event.preventDefault?.();
        restoreOpacityInput();
        input.focus?.();
      }
    });
    trigger.addEventListener("click", () => {
      panel.hidden = !panel.hidden;
      trigger.setAttribute("aria-expanded", String(!panel.hidden));
    });
    document.body.appendChild(trigger);
    document.body.appendChild(panel);
    applyMikuSettings(mikuSettings);
    return panel;
  };

  const syncMikuLayout = (home) => {
    const root = document.documentElement;
    if (!root || !document.body) return;
    root.classList.add("codex-miku-theme");
    root.classList.toggle("codex-miku-home", Boolean(home));
    root.classList.toggle("codex-miku-task", !home);
    if (home) mountMikuHome(home);
    else document.getElementById("codex-miku-home")?.remove();

    let ambient = document.getElementById("codex-miku-ambient");
    if (!ambient) {
      ambient = createMikuElement("div", "codex-miku-ambient");
      ambient.id = "codex-miku-ambient";
      ambient.setAttribute?.("aria-hidden", "true");
      document.body.appendChild(ambient);
    }
    mountMikuSettings();
    applyMikuSettings(mikuSettings);
  };

  const ensure = () => {
    if (window.__CODEX_DREAM_SKIN_DISABLED__) return;
    const root = document.documentElement;
    if (!root || !document.body) return;

    const shellMain = document.querySelector("main.main-surface");
    const shellSidebar = document.querySelector("aside.app-shell-left-panel");
    if (!shellMain || !shellSidebar) {
      clearSkinDom();
      return;
    }

    root.classList.add("codex-dream-skin");
    applyProfile(root);

    let style = document.getElementById(STYLE_ID);
    if (!style) {
      style = document.createElement("style");
      style.id = STYLE_ID;
      (document.head || root).appendChild(style);
    }
    if (style.dataset.dreamVersion !== "4") {
      style.textContent = cssText;
      style.dataset.dreamVersion = "4";
    }

    const home = document.querySelector('[role="main"]:has([data-testid="home-icon"])');
    const routeMains = Array.from(document.querySelectorAll('[role="main"]'));
    const routeSurfaces = routeMains.length > 0 ? routeMains : [shellMain];
    shellMain.classList.remove("dream-home", "dream-task");
    for (const candidate of routeSurfaces) {
      candidate.classList.toggle("dream-home", candidate === home);
      candidate.classList.toggle("dream-task", candidate !== home);
    }
    const utilityBars = new Set(home ? home.querySelectorAll('[class*="_homeUtilityBar_"]') : []);
    for (const candidate of document.querySelectorAll(`.${HOME_UTILITY_CLASS}`)) {
      if (!utilityBars.has(candidate)) candidate.classList.remove(HOME_UTILITY_CLASS);
    }
    for (const candidate of utilityBars) candidate.classList.add(HOME_UTILITY_CLASS);
    shellMain.classList.toggle("dream-home-shell", Boolean(home));

    let chrome = document.getElementById(CHROME_ID);
    if (!chrome || chrome.parentElement !== document.body) {
      chrome?.remove();
      chrome = document.createElement("div");
      chrome.id = CHROME_ID;
      chrome.setAttribute("aria-hidden", "true");
      document.body.appendChild(chrome);
    }
    chrome.classList.toggle("dream-home-shell", Boolean(home));
    syncMikuLayout(home);
  };

  const cleanup = () => {
    const state = window[STATE_KEY];
    if (state?.installToken !== installToken) return false;
    window.__CODEX_DREAM_SKIN_DISABLED__ = true;
    clearSkinDom();
    state?.observer?.disconnect();
    if (state?.timer) clearInterval(state.timer);
    if (state?.scheduler?.timeout) clearTimeout(state.scheduler.timeout);
    if (state?.artUrl) URL.revokeObjectURL(state.artUrl);
    delete window.__CODEX_MIKU_THEME_SETTINGS__;
    delete window[STATE_KEY];
    return true;
  };

  const scheduler = { timeout: null };
  const scheduleEnsure = () => {
    if (scheduler.timeout) clearTimeout(scheduler.timeout);
    scheduler.timeout = setTimeout(() => {
      scheduler.timeout = null;
      ensure();
    }, 180);
  };
  observer = new MutationObserver(() => {
    if (samplingNativeShell) return;
    scheduleEnsure();
  });
  observer.observe(document.documentElement, {
    childList: true,
    subtree: true,
    attributes: true,
    attributeFilter: ["class", "data-theme", "data-appearance", "data-color-mode"],
  });
  const timer = setInterval(ensure, 5000);
  window[STATE_KEY] = {
    ensure,
    cleanup,
    observer,
    timer,
    scheduler,
    artUrl,
    profile,
    config,
    installToken,
    findNativeComposer,
    setComposerPrompt,
    mountMikuHome,
    mountMikuSettings,
    applyMikuSettings,
    syncMikuLayout,
    version: "2.0.0",
  };
  ensure();
  analyzeArt().then((result) => {
    const state = window[STATE_KEY];
    if (state?.installToken !== installToken || window.__CODEX_DREAM_SKIN_DISABLED__) return;
    profile = result;
    state.profile = result;
    ensure();
  });
  return { installed: true, version: "2.0.0", adaptive: true, miku: true };
})(__DREAM_CSS_JSON__, __DREAM_ART_JSON__, __DREAM_THEME_JSON__, __DREAM_MIKU_SETTINGS_JSON__)
