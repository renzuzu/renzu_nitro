function playsound(table) {
    var file = table['file']
    var volume = table['volume']
    var audioPlayer = null;
    if (audioPlayer != null) {
        audioPlayer.pause();
    }
    if (volume == undefined) {
        volume = 0.2
    }
    audioPlayer = new Audio("./audio/" + file + ".ogg");
    audioPlayer.volume = volume;
    audioPlayer.play();
}

window.addEventListener('message', function(event) {
    var data = event.data;
    if (event.data.type == 'update') {
        SetProgressCircle(event.data.val)
    }
    if (event.data.type == 'show') {
        document.getElementById('simple').style.display = event.data.val;
    }

});

function SetProgressCircle(percent) {
    var e = document.getElementById('rpmpath');
    if (e) {
        let length = e.getTotalLength();
        let to = length * ((100 - percent) / 100);
        e.style.strokeDashoffset = to;
    }
}