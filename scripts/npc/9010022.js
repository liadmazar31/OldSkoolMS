/*
 * Dimensional Mirror – add/curate destinations here.
 * Each entry: [label, mapId, portal (optional, default 0), minLevel (optional), mesoCost (optional), questIdRequired (optional), trainingLevelRange (optional)]
 * trainingLevelRange format: "Lv.X-Y" (e.g., "Lv.1-20")
 *
 * Tip:
 *  - Use your GM command (!pos / !whereami) to get current mapId if needed.
 *  - For most towns, portal index 0 is fine. Some maps need a specific portal (e.g., 1).
 */

var DESTS = [
    // Victoria Island Towns
    ["Henesys",              100000000, 0, 0, 0, null, "Lv.1-20"],
    ["Kerning City",         103000000, 0, 0, 0, null, "Lv.10-30"],
    ["Ellinia",              101000000, 0, 0, 0, null, "Lv.20-40"],
    ["Perion",               102000000, 0, 0, 0, null, "Lv.15-35"],
    ["Lith Harbour",         104000000, 0, 0, 0, null, "Lv.10-25"],
    ["Sleepywood",           105040300, 0, 0, 0, null, "Lv.30-50"],
    ["Florina Beach",        110000000, 0, 0, 0, null, "Lv.25-45"],
    ["Nautilus Harbor",      120000000, 0, 0, 0, null, "Lv.1-10"],
    
    // Ossyria Towns
    ["Orbis",                200000000, 0, 0, 0, null, "Lv.50-70"],
    ["El Nath",              211000000, 0, 0, 0, null, "Lv.60-80"],
    ["Ludibrium",            220000000, 0, 0, 0, null, "Lv.35-60"],
    ["Omega Sector",         221000000, 0, 0, 0, null, "Lv.40-70"],
    ["Korean Folk Town",     222000000, 0, 0, 0, null, "Lv.50-80"],
    ["Aquarium",             230000000, 0, 0, 0, null, "Lv.60-90"],
    ["Leafre",               240000000, 0, 0, 0, null, "Lv.80-120"],
    ["Mu Lung",              250000000, 0, 0, 0, null, "Lv.90-130"],
    ["Herb Town",            251000000, 0, 0, 0, null, "Lv.100-140"],
    ["Ariant",               260000000, 0, 0, 0, null, "Lv.70-100"],
    ["Magatia",              261000000, 0, 0, 0, null, "Lv.100-150"],
    
    // Other Regions
    ["Ereve",                130000000, 0, 0, 0, null, "Lv.10-30"],
    ["Rien",                 140000000, 0, 0, 0, null, "Lv.30-60"],
    ["Temple of Time",       270000100, 0, 0, 0, null, "Lv.120-200"],
    ["Ellin Forest",         300000000, 0, 0, 0, null, "Lv.200-250"],
    ["New Leaf City",        600000000, 0, 0, 0, null, "Lv.100-150"],
    ["Amoria",               680000000, 0, 0, 0, null, "Lv.30-50"],
    ["Mushroom Shrine",      800000000, 0, 0, 0, null, "Lv.100-150"],
    ["Showa Town",           801000000, 0, 0, 0, null, "Lv.100-150"],
    ["Singapore",            540000000, 0, 0, 0, null, "Lv.100-180"],
    ["Boat Quay Town",       541000000, 0, 0, 0, null, "Lv.100-180"],
    ["Kampung Village",      551000000, 0, 0, 0, null, "Lv.120-200"],
    ["Mushroom Kingdom",     106020000, 0, 0, 0, null, "Lv.30-60"],
    ["Happyville",           209000000, 0, 0, 0, null, "Lv.1-10"],
    ["Neo City",             240070000, 0, 0, 0, null, "Lv.100-150"],
  
    // Gameplay hubs
    ["Free Market Entrance", 910000000, 0, 0, 0, null, "N/A"],
    ["Kerning PQ Lobby",     103000800, 0, 20, 0, null, "Lv.20-30"],
    ["Ludi PQ Lobby",        221024500, 0, 30, 0, null, "Lv.30-50"],
    // ["Zakum Altar",      280030000, 0, 50, 0, 100200, "Lv.50+"], // example requiring quest 100200
  ];
  
  function start() {
    var text = "Hello! I'm the Dimensional Mirror.\r\nWhere would you like to go?";
    var shown = 0;
    for (var i = 0; i < DESTS.length; i++) {
      var d = DESTS[i];
      var label   = d[0];
      var mapId   = d[1];
      var minLvl  = (d.length >= 4 && d[3] != null) ? d[3] : 0;
      var fee     = (d.length >= 5 && d[4] != null) ? d[4] : 0;
      var qid     = (d.length >= 6 && d[5] != null) ? d[5] : 0;
      var trainLvl = (d.length >= 7 && d[6] != null) ? d[6] : null;
  
      // gating
      if (minLvl > 0 && cm.getPlayer().getLevel() < minLvl) continue;
      if (qid > 0 && !cm.isQuestStarted(qid) && !cm.isQuestFinished(qid)) continue;
  
      text += "\r\n#L" + i + "# " + label;
      if (minLvl > 0) text += " #b(Lv." + minLvl + "+)#k";
      if (fee > 0)    text += " #r(" + fee + " mesos)#k";
      if (trainLvl)   text += " #e[" + trainLvl + "]#k";
      text += "#l";
      shown++;
    }
  
    if (shown === 0) {
      cm.sendOk("Looks like I have nowhere to send you right now.");
      cm.dispose();
      return;
    }
  
    cm.sendSimple(text);
  }
  
  function action(mode, type, sel) {
    if (mode != 1) { cm.dispose(); return; }
  
    if (sel < 0 || sel >= DESTS.length) { cm.dispose(); return; }
    var d = DESTS[sel];
  
    // Re-validate the same gates at selection time
    var label   = d[0];
    var mapId   = d[1];
    var portal  = (d.length >= 3 && d[2] != null) ? d[2] : 0;
    var minLvl  = (d.length >= 4 && d[3] != null) ? d[3] : 0;
    var fee     = (d.length >= 5 && d[4] != null) ? d[4] : 0;
    var qid     = (d.length >= 6 && d[5] != null) ? d[5] : 0;
  
    if (minLvl > 0 && cm.getPlayer().getLevel() < minLvl) {
      cm.sendOk("You must be at least level " + minLvl + " to go to #b" + label + "#k.");
      cm.dispose(); return;
    }
    if (qid > 0 && !cm.isQuestStarted(qid) && !cm.isQuestFinished(qid)) {
      cm.sendOk("You are not eligible to go there yet.");
      cm.dispose(); return;
    }
    if (fee > 0) {
      if (!cm.haveMeso(fee)) {
        cm.sendOk("You need #r" + fee + "#k mesos.");
        cm.dispose(); return;
      }
      cm.gainMeso(-fee);
    }
  
    cm.warp(mapId, portal);
    cm.dispose();
  }