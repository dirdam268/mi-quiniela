import { useState } from "react";

// ════════════════════════════════════════════════════════════════════════
// JORNADA 1 DE LA QUINIELA — TEMPORADA 2026/27 — BOLETO OFICIAL LAE
// Fuente: eduardolosilla.es · betbrothers.es · laliga.com · 14/08/2026
//
// NUEVA TEMPORADA 26/27:
// Ascendidos: Racing Santander · Deportivo La Coruña · Málaga (playoff)
// Descendidos (van a 2ª): Real Oviedo · Girona · Mallorca
//
// Europa 25/26: Barça campeón · Madrid 2º · Atlético 3º · Villarreal 4º
// Betis 5º (CL) · Celta 6º (EL) · R.Sociedad 7º (EL) · Getafe 8º (Conference)
//
// ⚠ INCIDENCIA: Celta-Osasuna SUSPENDIDO por mal estado del terreno.
// El resultado se decide por sorteo (59 bolas para el 1, 28 X, 13 para 2).
// Pronosticamos el 1 como más probable (59%).
//
// JORNADA 1 → sin historial de temporada · incertidumbre máxima
// Los % LAE son la referencia más fiable en jornada inicial
//
// 9 partidos 1ª División (J1 LaLiga, 15-18 agosto 2026)
// 5 partidos 2ª División (J1 Hypermotion, 15-18 agosto 2026)
// Pleno al 15: Deportivo La Coruña – Elche
// ════════════════════════════════════════════════════════════════════════

const BG="#09090f", SFC="#111118", BRD="#1a1a28", TXT="#e0e0f0", MUT="#555577";
const predColor = p => p==="1"?"#00ff88":p==="X"?"#ffaa00":"#ff4466";
const confC = c => c==="ALTA"?"#00ff88":c==="MEDIA"?"#ffaa00":"#555577";

const PARTIDOS = [
  // ── 1ª DIVISIÓN J1 ──────────────────────────────────────────────────
  {
    num:1, div:"1ª",
    local:"Dep. Alavés", el:"⚪", nota:"",
    visit:"Getafe", ev:"🔵", nota_v:"",
    dia:"Sáb·19:30", pred:"X", p1:38,px:37,p2:25,
    lae_1:40,lae_x:35,lae_2:25,
    razon:"Partido de apertura de temporada. Ambos equipos de zona media-baja con objetivos de permanencia. Sin historial de temporada, los % LAE casi igualados entre 1 y X. Apostamos al empate en un duelo muy equilibrado.",
    bajas:"Sin datos confirmados de pretemporada", conf:"BAJA"
  },
  {
    num:2, div:"1ª",
    local:"Sevilla", el:"⚪", nota:"",
    visit:"Rayo Vallecano", ev:"🔴", nota_v:"",
    dia:"Sáb·21:30", pred:"1", p1:41,px:30,p2:29,
    lae_1:54,lae_x:28,lae_2:18,
    razon:"Sevilla local con motivación de arrancar bien (zona media-alta). Rayo recién llegado de Conference League. En casa, el Ramón Sánchez-Pizjuán siempre aprieta. 54% LAE al 1.",
    bajas:"Sin datos confirmados", conf:"MEDIA"
  },
  {
    num:3, div:"1ª",
    local:"Racing Santander", el:"⚪", nota:"🆕 ASCENDIDO",
    visit:"Villarreal", ev:"🟡", nota_v:"",
    dia:"Dom·17:00", pred:"2", p1:15,px:22,p2:63,
    lae_1:19,lae_x:20,lae_2:61,
    razon:"Racing recién ascendido después de 14 años fuera de Primera. Villarreal 4º la temporada pasada, con objetivos Champions. Primera visita de Racing al Sardinero en Primera tras 14 años: ambiente espectacular pero rival superior. 61-63% al 2.",
    bajas:"Racing: adaptación a Primera · Villarreal: Foyth pendiente", conf:"ALTA"
  },
  {
    num:4, div:"1ª",
    local:"RCD Espanyol", el:"⚪", nota:"",
    visit:"Levante", ev:"🔵", nota_v:"",
    dia:"Dom·19:00", pred:"1", p1:46,px:29,p2:25,
    lae_1:61,lae_x:25,lae_2:14,
    razon:"Espanyol local, 61% LAE al 1. Levante sobrevivió al descenso por los pelos la temporada pasada (42pts, salvación in extremis). En el Cornellà, Espanyol debería ser superior.",
    bajas:"Sin datos confirmados", conf:"MEDIA"
  },
  {
    num:5, div:"1ª",
    local:"Celta Vigo", el:"🔵", nota:"⚠ SUSPENDIDO",
    visit:"Osasuna", ev:"🔴", nota_v:"",
    dia:"Lun·21:30", pred:"1", p1:58,px:26,p2:16,
    lae_1:59,lae_x:28,lae_2:13,
    razon:"⚠ PARTIDO SUSPENDIDO por mal estado del césped. El resultado se decide por sorteo con ~59 bolas para el 1, 28 para la X y 13 para el 2. Apostamos al 1 como más probable (59% de probabilidad en el sorteo).",
    bajas:"N/A — resultado por sorteo", conf:"BAJA"
  },
  // ── 2ª DIVISIÓN J1 ──────────────────────────────────────────────────
  {
    num:6, div:"2ª",
    local:"FC Andorra", el:"🔴", nota:"",
    visit:"AD Ceuta", ev:"🔵", nota_v:"",
    dia:"Sáb·17:00", pred:"1", p1:56,px:24,p2:20,
    lae_1:52,lae_x:27,lae_2:21,
    razon:"Andorra local en el Estadi Nacional. Ceuta repite en 2ª División. Andorra viene de décimo en 2ª la temporada pasada. Local favorito con ~52-61% LAE.",
    bajas:"", conf:"MEDIA"
  },
  {
    num:7, div:"2ª",
    local:"Cádiz", el:"🟡", nota:"",
    visit:"Celta Fortuna", ev:"🔵", nota_v:"🆕 ASCENDIDO",
    dia:"Sáb·19:00", pred:"1", p1:48,px:27,p2:25,
    lae_1:66,lae_x:21,lae_2:13,
    razon:"Cádiz busca el ascenso directo o playoff. Celta Fortuna recién ascendido desde 3ª (filial del Celta). 66% LAE al 1 muy contundente. Partido sin historia.",
    bajas:"", conf:"ALTA"
  },
  {
    num:8, div:"2ª",
    local:"Real Oviedo", el:"🔵", nota:"🔽 DESCENDIDO",
    visit:"Granada", ev:"🔴", nota_v:"",
    dia:"Sáb·19:00", pred:"1", p1:54,px:26,p2:20,
    lae_1:49,lae_x:30,lae_2:21,
    razon:"Oviedo regresa a Segunda con el Carlos Tartiere enardecido. Granada lleva en 2ª desde el 23/24. Oviedo debería ser candidato al ascenso directo con el apoyo de su afición. 55% LAE al 1.",
    bajas:"", conf:"MEDIA"
  },
  {
    num:9, div:"2ª",
    local:"RCD Mallorca", el:"🔴", nota:"🔽 DESCENDIDO",
    visit:"R. Valladolid", ev:"🟣", nota_v:"",
    dia:"Sáb·21:30", pred:"1", p1:56,px:26,p2:18,
    lae_1:71,lae_x:19,lae_2:10,
    razon:"Mallorca cae a 2ª tras 5 años en Primera (42pts le costaron el descenso). En Son Moix con motivación máxima para volver. Valladolid también en 2ª con ambiciones. 71% LAE al 1.",
    bajas:"", conf:"ALTA"
  },
  // ── 2ª DIVISIÓN (continuación) ────────────────────────────────────────
  {
    num:10, div:"2ª",
    local:"SD Eibar", el:"🔵", nota:"",
    visit:"Tenerife", ev:"🔵", nota_v:"🆕 ASCENDIDO",
    dia:"Dom·17:00", pred:"1", p1:49,px:29,p2:22,
    lae_1:57,lae_x:26,lae_2:17,
    razon:"Eibar cerró la temporada pasada fuera del playoff. Tenerife sube desde Primera Federación. Ipurua siempre es difícil. 57-62% LAE al 1.",
    bajas:"", conf:"MEDIA"
  },
  {
    num:11, div:"2ª",
    local:"Burgos CF", el:"⚪", nota:"",
    visit:"Córdoba", ev:"🟢", nota_v:"",
    dia:"Dom·19:00", pred:"X", p1:41,px:29,p2:30,
    lae_1:46,lae_x:31,lae_2:23,
    razon:"Burgos vs Córdoba en El Plantío, duelo de zona media. Los dos quedaron fuera del playoff la pasada temporada. Muy igualado, apostamos al empate como valor.",
    bajas:"", conf:"BAJA"
  },
  {
    num:12, div:"2ª",
    local:"Girona", el:"🔴", nota:"🔽 DESCENDIDO",
    visit:"CD Leganés", ev:"🔵", nota_v:"",
    dia:"Dom·19:00", pred:"1", p1:57,px:26,p2:17,
    lae_1:62,lae_x:23,lae_2:15,
    razon:"Girona regresa a 2ª (41pts en Primera). Candidato top al ascenso directo. Leganés lleva ya varios años en 2ª. En Montilivi el apoyo será total. 62-68% LAE al 1.",
    bajas:"", conf:"ALTA"
  },
  {
    num:13, div:"2ª",
    local:"UD Las Palmas", el:"🟡", nota:"",
    visit:"Albacete", ev:"🔵", nota_v:"",
    dia:"Dom·21:30", pred:"1", p1:57,px:25,p2:18,
    lae_1:64,lae_x:21,lae_2:15,
    razon:"Las Palmas quedó 5ª en playoff y no ascendió. Albacete consolidado en 2ª. En el Gran Canaria, Las Palmas debería ganar. 64-76% LAE al 1.",
    bajas:"", conf:"ALTA"
  },
  {
    num:14, div:"2ª",
    local:"Sporting Gijón", el:"🔴", nota:"",
    visit:"Sabadell", ev:"⚪", nota_v:"🆕 ASCENDIDO",
    dia:"Lun·19:00", pred:"1", p1:51,px:28,p2:21,
    lae_1:67,lae_x:20,lae_2:13,
    razon:"Sporting en El Molinón ante el Sabadell recién ascendido desde 1ª Federación. El Molinón vuelve a rugir. 67-68% LAE al 1 muy contundente.",
    bajas:"", conf:"ALTA"
  },
  // ── PLENO AL 15 ─────────────────────────────────────────────────────
  {
    num:15, div:"P15",
    local:"RC Deportivo", el:"🔵", nota:"🆕 ASCENDIDO",
    visit:"Elche", ev:"🟢", nota_v:"",
    dia:"Lun·21:00",
    pred:"1", p1:0,px:0,p2:0,
    pleno_pred:"1-0",
    lae_p15_local:[7,49,37,7],
    lae_p15_visit:[24,60,14,2],
    razon:"Deportivo regresa a Primera División tras muchos años. Elche busca consolidarse en la categoría. El Riazor de gala para el debut. LAE: goles local 49% al 1 (muy probable). Visitante 60% al 1. Apuesta por partido de pocos goles: 1-0.",
    bajas:"Sin datos confirmados", conf:"MEDIA"
  },
];

function BarLAE({l1,lx,l2}) {
  return (
    <div style={{marginTop:4}}>
      <div style={{display:"flex",gap:1,height:4,width:"100%"}}>
        <div style={{height:"100%",width:`${l1}%`,background:"#00ff88",borderRadius:1,opacity:0.7}}/>
        <div style={{height:"100%",width:`${lx}%`,background:"#ffaa00",borderRadius:1,opacity:0.7}}/>
        <div style={{height:"100%",width:`${l2}%`,background:"#ff4466",borderRadius:1,opacity:0.7}}/>
      </div>
      <div style={{display:"flex",gap:5,fontFamily:"monospace",fontSize:"0.46rem",color:"#444466",marginTop:2}}>
        <span style={{color:"#00ff8866"}}>1</span>{l1}%
        <span style={{color:"#ffaa0066"}}>X</span>{lx}%
        <span style={{color:"#ff446666"}}>2</span>{l2}%
        <span style={{marginLeft:3,color:"#2a2a4a"}}>% LAE</span>
      </div>
    </div>
  );
}

function Partido({p,exp,setExp}) {
  const open=exp===p.num;
  const isP15=p.div==="P15";
  const divColor=p.div==="1ª"?"#e8ff00":p.div==="2ª"?"#44aaff":"#ff88aa";
  const isSusp=p.num===5;

  return (
    <div onClick={()=>setExp(open?null:p.num)}
      style={{background:SFC,border:`1px solid ${open?"#2a2a55":isSusp?"#ffaa00":"#1a1a28"}`,padding:"9px 11px",marginBottom:4,cursor:"pointer"}}>
      {isSusp && <div style={{fontFamily:"monospace",fontSize:"0.43rem",color:"#ffaa00",marginBottom:3}}>⚠ SUSPENDIDO — resultado por sorteo</div>}
      {p.nota && <div style={{fontFamily:"monospace",fontSize:"0.43rem",color:"#44aaff",marginBottom:3}}>{p.nota}</div>}
      <div style={{display:"grid",gridTemplateColumns:"26px 1fr auto 1fr auto",gap:5,alignItems:"center"}}>
        <div style={{textAlign:"center"}}>
          <div style={{fontFamily:"monospace",fontSize:"0.66rem",fontWeight:900,color:"#444466",lineHeight:1}}>{p.num}</div>
          <div style={{fontFamily:"monospace",fontSize:"0.42rem",color:divColor}}>{p.div}</div>
        </div>
        <div style={{display:"flex",alignItems:"center",gap:5,minWidth:0}}>
          <span style={{fontSize:"0.72rem",flexShrink:0}}>{p.el}</span>
          <div style={{minWidth:0}}>
            <div style={{fontSize:"0.7rem",fontWeight:600,color:TXT,lineHeight:1.2,whiteSpace:"nowrap",overflow:"hidden",textOverflow:"ellipsis"}}>{p.local}</div>
          </div>
        </div>
        <div style={{textAlign:"center",minWidth:36}}>
          <div style={{fontFamily:"monospace",fontSize:"0.4rem",color:"#1e1e2a"}}>{p.dia}</div>
          <div style={{fontWeight:900,fontSize:"0.62rem",color:BRD}}>VS</div>
        </div>
        <div style={{display:"flex",alignItems:"center",gap:5,flexDirection:"row-reverse",minWidth:0}}>
          <span style={{fontSize:"0.72rem",flexShrink:0}}>{p.ev}</span>
          <div style={{minWidth:0,textAlign:"right"}}>
            <div style={{fontSize:"0.7rem",fontWeight:600,color:TXT,lineHeight:1.2,whiteSpace:"nowrap",overflow:"hidden",textOverflow:"ellipsis"}}>{p.visit}</div>
            {p.nota_v && <div style={{fontFamily:"monospace",fontSize:"0.41rem",color:"#44aaff"}}>{p.nota_v}</div>}
          </div>
        </div>
        <div style={{display:"flex",flexDirection:"column",alignItems:"flex-end",minWidth:76,gap:2}}>
          {isP15?(
            <div style={{textAlign:"right"}}>
              <div style={{fontWeight:900,fontSize:"0.86rem",color:"#ff88aa",border:"1px solid #ff88aa44",background:"#ff88aa08",padding:"1px 7px"}}>{p.pleno_pred}</div>
              <div style={{fontFamily:"monospace",fontSize:"0.41rem",color:"#ff88aa55",marginTop:1}}>PLENO</div>
            </div>
          ):(
            <>
              <div style={{fontWeight:900,fontSize:"1.05rem",color:predColor(p.pred),border:`1px solid ${predColor(p.pred)}44`,background:`${predColor(p.pred)}08`,padding:"1px 7px"}}>{p.pred}</div>
              <div style={{display:"flex",gap:1,width:"100%",height:3}}>
                <div style={{height:"100%",width:`${p.p1}%`,background:"#00ff88",borderRadius:1}}/>
                <div style={{height:"100%",width:`${p.px}%`,background:"#ffaa00",borderRadius:1}}/>
                <div style={{height:"100%",width:`${p.p2}%`,background:"#ff4466",borderRadius:1}}/>
              </div>
              <div style={{fontFamily:"monospace",fontSize:"0.42rem",color:"#2a2a4a",display:"flex",gap:2}}>
                <span style={{color:"#00ff8877"}}>1</span>{p.p1}%
                <span style={{color:"#ffaa0077"}}>X</span>{p.px}%
                <span style={{color:"#ff446677"}}>2</span>{p.p2}%
              </div>
              <div style={{fontFamily:"monospace",fontSize:"0.41rem",color:confC(p.conf)}}>● {p.conf}</div>
            </>
          )}
        </div>
      </div>
      {open&&(
        <div style={{marginTop:8,paddingTop:8,borderTop:`1px solid ${BRD}`}}>
          <div style={{fontFamily:"monospace",fontSize:"0.57rem",color:"#8888bb",lineHeight:1.6,marginBottom:5}}>💡 {p.razon}</div>
          {p.bajas&&<div style={{fontFamily:"monospace",fontSize:"0.46rem",color:"#ff7777",marginBottom:5}}>⚕ {p.bajas}</div>}
          {!isP15&&<BarLAE l1={p.lae_1} lx={p.lae_x} l2={p.lae_2}/>}
          {isP15&&(
            <div style={{fontFamily:"monospace",fontSize:"0.44rem",color:MUT,marginTop:4}}>
              <div style={{color:"#ff88aa66",marginBottom:2}}>% LAE goles · {p.local.split(" ")[0]} / {p.visit.split(" ")[0]}:</div>
              <div>Local: {["0","1","2","M"].map((g,i)=>`${g}:${p.lae_p15_local[i]}%`).join(" · ")}</div>
              <div>Visit: {["0","1","2","M"].map((g,i)=>`${g}:${p.lae_p15_visit[i]}%`).join(" · ")}</div>
            </div>
          )}
        </div>
      )}
    </div>
  );
}

function Boleto() {
  const [cop,setCop]=useState(false);
  function copiar(){
    const p14=PARTIDOS.filter(p=>p.div!=="P15").map(p=>`${p.num}. ${p.local} - ${p.visit}: ${p.pred}`).join("\n");
    const p15=PARTIDOS.find(p=>p.div==="P15");
    navigator.clipboard.writeText(p14+`\n15. ${p15.local} - ${p15.visit}: ${p15.pleno_pred} (Pleno)`).then(()=>{setCop(true);setTimeout(()=>setCop(false),2000);});
  }
  const prim=PARTIDOS.filter(p=>p.div==="1ª");
  const seg=PARTIDOS.filter(p=>p.div==="2ª");
  const p15=PARTIDOS.find(p=>p.div==="P15");
  return (
    <div style={{background:"#0c0c18",border:"1px solid #e8ff0033",padding:"10px 12px",marginTop:4}}>
      <div style={{display:"flex",alignItems:"center",justifyContent:"space-between",marginBottom:7}}>
        <div>
          <div style={{fontWeight:900,fontSize:"0.84rem",color:"#e8ff00",letterSpacing:"0.06em"}}>BOLETO OFICIAL · J1 · 26/27</div>
          <div style={{fontFamily:"monospace",fontSize:"0.43rem",color:MUT}}>14 partidos + Pleno al 15</div>
        </div>
        <button onClick={copiar} style={{fontFamily:"monospace",fontSize:"0.5rem",background:cop?"#e8ff00":"transparent",color:cop?"#000":"#e8ff00",border:"1px solid #e8ff0055",padding:"3px 8px",cursor:"pointer",textTransform:"uppercase"}}>
          {cop?"✓ OK":"📋 COPIAR"}
        </button>
      </div>
      <div style={{display:"grid",gridTemplateColumns:"1fr 1fr",gap:"1px 12px"}}>
        <div>
          <div style={{fontFamily:"monospace",fontSize:"0.44rem",color:"#e8ff0044",letterSpacing:"0.1em",marginBottom:3}}>1ª DIV · J1</div>
          {prim.map(p=>(
            <div key={p.num} style={{display:"flex",gap:4,alignItems:"center",padding:"3px 0",borderBottom:"1px solid #111122",fontFamily:"monospace"}}>
              <span style={{color:"#1e1e2e",width:12,flexShrink:0,fontSize:"0.47rem"}}>{p.num}</span>
              <span style={{flex:1,color:"#777799",fontSize:"0.52rem",overflow:"hidden",textOverflow:"ellipsis",whiteSpace:"nowrap"}}>{p.local.split(" ")[0]} — {p.visit.split(" ")[0]}</span>
              <span style={{fontWeight:900,fontSize:"0.74rem",color:predColor(p.pred),width:11,textAlign:"center",flexShrink:0}}>{p.pred}</span>
            </div>
          ))}
        </div>
        <div>
          <div style={{fontFamily:"monospace",fontSize:"0.44rem",color:"#44aaff44",letterSpacing:"0.1em",marginBottom:3}}>2ª DIV · J1</div>
          {seg.map(p=>(
            <div key={p.num} style={{display:"flex",gap:4,alignItems:"center",padding:"3px 0",borderBottom:"1px solid #111122",fontFamily:"monospace"}}>
              <span style={{color:"#1e1e2e",width:12,flexShrink:0,fontSize:"0.47rem"}}>{p.num}</span>
              <span style={{flex:1,color:"#777799",fontSize:"0.52rem",overflow:"hidden",textOverflow:"ellipsis",whiteSpace:"nowrap"}}>{p.local.split(" ")[0]} — {p.visit.split(" ")[0]}</span>
              <span style={{fontWeight:900,fontSize:"0.74rem",color:predColor(p.pred),width:11,textAlign:"center",flexShrink:0}}>{p.pred}</span>
            </div>
          ))}
          <div style={{marginTop:5,paddingTop:4,borderTop:"1px solid #1a1a2a"}}>
            <div style={{fontFamily:"monospace",fontSize:"0.44rem",color:"#ff88aa44",letterSpacing:"0.1em",marginBottom:3}}>PLENO AL 15</div>
            <div style={{display:"flex",gap:4,alignItems:"center",fontFamily:"monospace"}}>
              <span style={{color:"#1e1e2e",width:12,flexShrink:0,fontSize:"0.47rem"}}>15</span>
              <span style={{flex:1,color:"#777799",fontSize:"0.52rem"}}>{p15.local.split(" ")[0]} — {p15.visit.split(" ")[0]}</span>
              <span style={{fontWeight:900,fontSize:"0.74rem",color:"#ff88aa"}}>{p15.pleno_pred}</span>
            </div>
          </div>
        </div>
      </div>
      <div style={{display:"flex",gap:9,fontFamily:"monospace",fontSize:"0.47rem",color:MUT,marginTop:7,flexWrap:"wrap"}}>
        {["1","X","2"].map(r=>{const n=PARTIDOS.filter(p=>p.div!=="P15"&&p.pred===r).length;const c=r==="1"?"#00ff88":r==="X"?"#ffaa00":"#ff4466";return n>0?<span key={r}><span style={{color:c}}>{r}</span>×{n}</span>:null;})}
        <span style={{color:"#ff88aa"}}>P15: {p15.pleno_pred}</span>
        <span style={{marginLeft:"auto",color:"#1a1a2a",fontSize:"0.41rem"}}>eduardolosilla.es · 14/08/26</span>
      </div>
    </div>
  );
}

export default function App() {
  const [exp,setExp]=useState(null);
  const [filtro,setFiltro]=useState("todos");
  const partidos=filtro==="todos"?PARTIDOS:filtro==="1a"?PARTIDOS.filter(p=>p.div==="1ª"):PARTIDOS.filter(p=>p.div==="2ª"||p.div==="P15");
  return (
    <div style={{fontFamily:"system-ui,sans-serif",background:BG,color:TXT,minHeight:"100vh"}}>
      <div style={{padding:"12px 12px 9px",borderBottom:`1px solid ${BRD}`}}>
        <div style={{display:"flex",alignItems:"flex-start",justifyContent:"space-between",gap:8}}>
          <div>
            <div style={{fontWeight:900,fontSize:"clamp(1.4rem,5vw,2rem)",color:"#e8ff00",letterSpacing:"0.04em",lineHeight:1}}>QUINIELA IA</div>
            <div style={{fontFamily:"monospace",fontSize:"0.47rem",color:MUT,letterSpacing:"0.12em",textTransform:"uppercase",marginTop:2}}>J1 · Temporada 2026/27 · Nueva temporada</div>
          </div>
          <div style={{textAlign:"right"}}>
            <div style={{fontFamily:"monospace",fontSize:"0.55rem",background:SFC,border:"1px solid #222244",color:"#7777aa",padding:"3px 7px"}}>J1 · 26/27</div>
            <div style={{fontFamily:"monospace",fontSize:"0.45rem",color:"#1e1e2e",marginTop:2}}>15–18 Ago 2026</div>
          </div>
        </div>
        <div style={{fontFamily:"monospace",fontSize:"0.46rem",color:"#44aaff",background:"rgba(68,170,255,0.04)",border:"1px solid rgba(68,170,255,0.14)",padding:"3px 7px",marginTop:6,lineHeight:1.5}}>
          🆕 Suben: Racing Santander · Deportivo La Coruña · Málaga (playoff) · Bajan: Oviedo · Girona · Mallorca
        </div>
        <div style={{fontFamily:"monospace",fontSize:"0.44rem",color:"#ffaa00",background:"rgba(255,170,0,0.04)",border:"1px solid rgba(255,170,0,0.14)",padding:"3px 7px",marginTop:4,lineHeight:1.5}}>
          ⚠ Partido 5 (Celta-Osasuna) SUSPENDIDO — resultado por sorteo (59% al 1)
        </div>
      </div>
      <div style={{display:"flex",borderBottom:`1px solid ${BRD}`}}>
        {[{id:"todos",label:"Todos (14+P15)"},{id:"1a",label:"1ª · J1"},{id:"2a",label:"2ª · J1 + Pleno"}].map(f=>(
          <button key={f.id} onClick={()=>{setFiltro(f.id);setExp(null);}}
            style={{flex:1,fontFamily:"monospace",fontSize:"0.52rem",background:"transparent",border:"none",padding:"8px 4px",color:filtro===f.id?"#e8ff00":MUT,borderBottom:filtro===f.id?"2px solid #e8ff00":"2px solid transparent",cursor:"pointer",textTransform:"uppercase"}}>
            {f.label}
          </button>
        ))}
      </div>
      <div style={{padding:"9px 11px 0",maxWidth:900,margin:"0 auto"}}>
        {partidos.map(p=><Partido key={p.num} p={p} exp={exp} setExp={setExp}/>)}
        <div style={{fontFamily:"monospace",fontSize:"0.43rem",color:"#151525",textAlign:"center",marginBottom:7}}>
          Toca cada partido · análisis · % LAE reales
        </div>
        {filtro==="todos"&&<Boleto/>}
      </div>
      <div style={{fontFamily:"monospace",fontSize:"0.4rem",color:"#0e0e1a",padding:"7px 11px",textAlign:"center",marginTop:5}}>
        ⚠ Solo orientativo · eduardolosilla.es · 14/08/2026
      </div>
    </div>
  );
}
