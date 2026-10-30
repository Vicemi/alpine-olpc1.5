// Low-RAM defaults for the XO-1.5 (1 GB, VIA C7). Users can still change them in about:config.
pref("dom.ipc.processCount", 1);
pref("dom.ipc.processCount.webIsolated", 1);
pref("fission.autostart", false);
pref("browser.tabs.unloadOnLowMemory", true);
pref("browser.sessionstore.interval", 60000);
pref("browser.cache.disk.capacity", 51200);
pref("general.smoothScroll", false);
pref("toolkit.cosmeticAnimations.enabled", false);
pref("gfx.webrender.software", true);
pref("media.hardware-video-decoding.enabled", false);
pref("browser.startup.homepage", "https://duckduckgo.com/");
pref("browser.aboutwelcome.enabled", false);
pref("datareporting.policy.dataSubmissionEnabled", false);
pref("toolkit.telemetry.enabled", false);
pref("browser.newtabpage.activity-stream.feeds.topsites", false);
pref("browser.newtabpage.activity-stream.feeds.section.topstories", false);
