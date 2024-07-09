window.addEventListener("message", function (event) {
    var data = event.data;

    if(data.action == 'startCamera'){
        $("#flash_icon").removeClass('active')
        $("#flash_desc").html('OFF')

        $("#camera").removeClass('isDisable')
        $("body").removeClass('isDisable')
    }else if(data.action == 'setFlash'){
        if(data.flash){
            $("#flash_icon").addClass('active')
            $("#flash_desc").html('ON')
        }else{
            $("#flash_icon").removeClass('active')
            $("#flash_desc").html('OFF')
        }
        
    }else if(data.action == 'updateZoom'){
        $("#zoom").html(data.zoom+'X ZOOM')
    }else if(data.action == 'finishCamera'){
        $("body").addClass('isDisable')
        $("#camera").addClass('isDisable')
        
        $("#zoom").html('1X ZOOM')
        $("#flash_icon").removeClass('active')
        $("#flash_desc").html('OFF')

    }else if(data.action == 'openPhoto'){
        $("#photo_img").css('background-image','url('+data.url+')')
        $("#photo_details").html(data.description.replace('\n','<br>'))
        $("#photo").removeClass('isDisable')
        $("body").removeClass('isDisable')
    }
    
})

document.onkeyup = function (data) {
    let key = data.key.toUpperCase()
  
    if (key == "ESC" || key == "ESCAPE") {
        if (!$("#photo").hasClass('isDisable')) {
            $("body").addClass('isDisable')
            $("#photo").addClass('isDisable')
            $("#photo_details").html('')
            $("#photo_img").css('background-image','url()')

            $.post(`https://${GetParentResourceName()}/close`);
        }
    }
  };
