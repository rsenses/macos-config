import { View, div } from "gpui-kit";
import { hc, home, props, theme, closeOverlay, openOverlay } from "herdr";

export default class SessionizerPopup extends View {
  init(_props, cx) {
    if (props()?.terminal) return;
    const launcher = props()?.overlay;
    cx.spawn(async (cx) => {
      try {
        const result = await hc(["run", "--bg", "--json", "--rm", "--no-notify", "--no-parent", "--", "/bin/bash", `${home()}/.local/bin/herdr-app-sessionizer`]);
        const terminal = JSON.parse(result.stdout).address;
        if (!terminal) throw new Error("No se pudo iniciar la terminal");
        closeOverlay(launcher);
        openOverlay({ kind: "dialog", width: 0.8, height: 0.8, layout: {
          type: "column", children: [
            { type: "block", size: { px: 32 }, content: { mod: "sessionizer-popup", props: { terminal } } },
            { type: "block", content: { terminal } }
          ]
        }});
      } catch (e) {
        this.error = String(e);
        cx.notify();
      }
    });
  }

  async close() {
    const terminal = props()?.terminal;
    if (terminal) await hc(["kill", terminal]);
  }

  render() {
    const t = theme();
    const p = props() ?? {};
    return div().size_full().px(12).bg(t.surface).text_color(t.foreground)
      .child(p.terminal ? "Sessionizer" : (this.error || "Abriendo sessionizer…"))
      .when(Boolean(p.terminal), el => el.child(div().id("close").cursor_pointer().child("✕").on_click(() => {
        hc(["kill", p.terminal]);
        closeOverlay(p.overlay);
      })));
  }
}
