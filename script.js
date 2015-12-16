var Player = function(id) {
   var p = {

   }
   return p
}

var players = []
var timerRunning = false;
var winHandled = false;
var connected = false;

var initWS = function(wsIP){
   var ws = new WebSocket("ws://"+wsIP);
   ws.onmessage = function(e){
      if (!connected) {
         connected = true;
         $('.db').show();
         $('#loading').hide();
      }
      handleData(JSON.parse(e.data));
   }
};

var handleData = function(d){
   console.log(d);
   window.latestData = d;
   updateScore(d);
   updateMoney(d);
};

var updateScore = function(d){
   var map = d.map.name
   var roundNum = d.map.round
   var tScore = d.map.team_t.score
   var ctScore = d.map.team_ct.score
   var roundPhase = d.round.phase
   if (d.round.bomb === "planted") {
      startBombTimer();
   }

   if (roundPhase === "over"){
      handleWin(d.round.win_team);
      stopBombTimer();
   } else {
      winHandled = false;
   }

   if (roundPhase === "over"){
      handleWin(d.round.win_team);
   } else {
      winHandled = false;
   }

   $('#score').text(ctScore + " - " + tScore);
   $('#roundnum').text("ROUND " + roundNum + " OUT OF 30");
}

var startBombTimer = function(){
   if (!timerRunning){
      timerRunning = true;
      window.bombTime = 40.0;
      $('#bomb').show();
      $('#no-bomb').hide();
      window.bombTimer = setInterval(function(){
         window.bombTime -= 0.1
         $('#btime').text(Math.round(window.bombTime*10)/10);
         $('#defuse').text(window.bombTime > 5 ? "You can defuse." : "No time! Run!")
      }, 100);
   }
}

var stopBombTimer = function(){
   clearInterval(window.bombTimer);
   timerRunning = false;
   $('#bomb').hide();
   $('#no-bomb').show();
}

var updateHealth = function(){

};

var updateMoney = function(d){
   var playerMoney = d.player.state.money
   $('#money').text("$"+playerMoney)
};

var updateKills = function(){

};

var handleWin = function(win_team){
   if (!winHandled){
      var text = (win_team === "T" ? "Terrorists" : "Counter Terrorists");
      alert(text + " win the round!");
      winHandled = true;
   }
}

var ping = function(dq){
   var d = dq || window.latestData;
   return Date.now() - d.provider.timestamp
}

initWS(window.location.host);