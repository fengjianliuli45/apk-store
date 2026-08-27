import { useMemo, useState, type CSSProperties } from "react";
import {
  BarChartIcon,
  CalendarIcon,
  CameraIcon,
  Cross2Icon,
  LightningBoltIcon,
  MixerHorizontalIcon,
  PersonIcon,
  SewingPinFilledIcon,
} from "@radix-ui/react-icons";
import { MobileScroll } from "./mobile";

type FxStyle = CSSProperties & Record<`--${string}`, string | number>;

const navItems = [
  { label: "计划", icon: CalendarIcon },
  { label: "数据", icon: BarChartIcon },
  { label: "训练", icon: LightningBoltIcon },
  { label: "社区", icon: SewingPinFilledIcon },
  { label: "我的", icon: PersonIcon },
];

export default function Prototype() {
  const [activeTab, setActiveTab] = useState("训练");
  const [controlsOpen, setControlsOpen] = useState(false);
  const [intensity, setIntensity] = useState(86);
  const [speed, setSpeed] = useState(55);
  const [reducedMotion, setReducedMotion] = useState(false);
  const [listening, setListening] = useState(false);
  const [starting, setStarting] = useState(false);

  const particles = useMemo(
    () =>
      Array.from({ length: 38 }, (_, index) => ({
        id: index,
        x: (index * 37 + 11) % 100,
        y: (index * 61 + 7) % 100,
        size: 2 + ((index * 7) % 4),
        delay: -((index * 1.37) % 12),
        duration: 11 + ((index * 13) % 16),
      })),
    [],
  );

  const fxStyle: FxStyle = {
    "--fx-intensity": intensity / 100,
    "--fx-speed": `${Math.max(8, 32 - speed * 0.22)}s`,
    "--fx-speed-slow": `${Math.max(10, 39 - speed * 0.26)}s`,
    "--fx-speed-fast": `${Math.max(7, 27 - speed * 0.18)}s`,
  };

  const startTraining = () => {
    setStarting(true);
    window.setTimeout(() => setStarting(false), 1600);
  };

  return (
    <div
      className={`stopwatch-app ${reducedMotion ? "reduce-motion" : ""} ${listening ? "is-listening" : ""}`}
      style={fxStyle}
    >
      <div className="ambient" aria-hidden="true">
        <div className="mist mist-a" />
        <div className="mist mist-b" />
        <div className="mist mist-c" />
        <div className="flow-line flow-one" />
        <div className="flow-line flow-two" />
        <div className="particle-field">
          {particles.map((particle) => (
            <i
              key={particle.id}
              className="particle"
              style={
                {
                  left: `${particle.x}%`,
                  top: `${particle.y}%`,
                  width: particle.size,
                  height: particle.size,
                  animationDelay: `${particle.delay}s`,
                  animationDuration: `${particle.duration}s`,
                } as CSSProperties
              }
            />
          ))}
        </div>
      </div>

      <MobileScroll className="app-screen effects-scroll">
        <main className="screen-content training-home" aria-label="Stopwatch 训练首页特效原型">
          <header className="home-header">
            <div>
              <p className="date-line">8月27日 · 星期四</p>
              <h1>今日训练</h1>
              <p className="workout-meta">上肢力量 · 45分钟 · 6个动作</p>
            </div>
            <button
              className="fx-trigger"
              type="button"
              aria-label="打开特效设置"
              aria-expanded={controlsOpen}
              onClick={() => setControlsOpen((open) => !open)}
            >
              {controlsOpen ? <Cross2Icon /> : <MixerHorizontalIcon />}
            </button>
          </header>

          {controlsOpen && (
            <section className="fx-panel" aria-label="特效设置">
              <label>
                <span>特效强度</span>
                <output>{intensity}%</output>
                <input
                  type="range"
                  min="20"
                  max="100"
                  value={intensity}
                  onChange={(event) => setIntensity(Number(event.target.value))}
                />
              </label>
              <label>
                <span>流动速度</span>
                <output>{speed}%</output>
                <input
                  type="range"
                  min="10"
                  max="100"
                  value={speed}
                  onChange={(event) => setSpeed(Number(event.target.value))}
                />
              </label>
              <button
                className={`motion-toggle ${reducedMotion ? "active" : ""}`}
                type="button"
                onClick={() => setReducedMotion((reduced) => !reduced)}
              >
                减少动态效果 <strong>{reducedMotion ? "开" : "关"}</strong>
              </button>
            </section>
          )}

          <section className="training-portal" aria-label="今日训练内容">
            <div className="portal-progress" />
            <div className="portal-grid" />
            <div className="portal-copy">
              <h2>胸背强化</h2>
              <p>第 2 周 · 第 3 次</p>
              <span />
              <p className="next-move">下一动作 <strong>深蹲</strong></p>
            </div>
          </section>

          <button className="start-button" type="button" onClick={startTraining}>
            <LightningBoltIcon />
            <span>{starting ? "训练舱准备中…" : "开始训练"}</span>
          </button>
          <button className="plan-link" type="button" onClick={() => setActiveTab("计划")}>
            查看今日计划 <span aria-hidden="true">›</span>
          </button>

          <section className="assistant-zone" aria-label="语音助手">
            <button
              className="voice-core"
              type="button"
              aria-label={listening ? "停止聆听" : "开始语音输入"}
              aria-pressed={listening}
              onClick={() => setListening((value) => !value)}
            >
              <span className="voice-inner" />
            </button>
            <p>{listening ? "正在聆听…" : "有什么可以帮你的？"}</p>
          </section>

          <button className="meal-button" type="button">
            <CameraIcon />
            <span>记录饮食</span>
          </button>
        </main>
      </MobileScroll>

      <nav className="bottom-dock" aria-label="主要导航">
        {navItems.map(({ label, icon: Icon }) => (
          <button
            key={label}
            className={activeTab === label ? "selected" : ""}
            type="button"
            onClick={() => setActiveTab(label)}
            aria-current={activeTab === label ? "page" : undefined}
          >
            <Icon />
            <span>{label}</span>
          </button>
        ))}
      </nav>
    </div>
  );
}
