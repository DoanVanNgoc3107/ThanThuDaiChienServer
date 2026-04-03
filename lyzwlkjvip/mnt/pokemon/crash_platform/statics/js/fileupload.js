$(function () {
    // File upload
    function uploadFile() {

    }
    $("#upload_file").on("click", function() {
        var url;
        var phoneSys = $("#phone-sys").val();
        if (phoneSys === "Android") {
            url = "/fileupload";
        } else if (phoneSys === "IOS") {
            url = "/ios_upload";
        } else {
            alert("Không xác định nền tảng?")
            return
        }
        var versionId = $("#fileupload-versionid").val();
        var package = $("#fileupload-package").val();
        var game_name = $("#fileupload-game_name").val();
        var file = $("#i-file").prop('files')[0];

        if (versionId === "" | package === "" | game_name === "") {
            alert("Phiên bản và gói ứng dụng không được để trống");
            return
        } else if ((file.size === 0) || (!file)) {
            alert("Tệp tải lên không được để trống");
            return
        } else {
            var form = new FormData();
            form.append("versionId", versionId);
            form.append("package", package);
            form.append("game_name", game_name);
            form.append("uploadFile", file);

            $.ajax({
                url: url,
                type: "post",
                async: true,
                data: form,
                contentType: false,
                processData: false,
                beforeSend: function(xhr) {
                    $('#progressBar').css("display", "block")
                    $("#upload_file").attr("disabled", "disabled")
                },
                complete: function(xhr, status) {
                    $('#progressBar').css("display", "none")
                    $("#upload_file").removeAttr("disabled")
                },
                // xhr: function() {
                //     myXhr = $.ajaxSettings.xhr();
                //     if(myXhr.upload){
                //         myXhr.upload.addEventListener('progress', function(e) {
                //             if (e.lengthComputable) {
                //                 $('#progressBar').css("display", "block")
                //             }
                //         }, false);
                //     }
                //     return myXhr;
                // },
                success: function(ret) {
                    var ret = JSON.parse(ret);
                    if (!ret.result) {
                        alert("Tải lên thất bại!");
                        console.log(ret.msg);
                        return;
                    }
                    alert("Tải lên thành công!");
                    $("#fileupload-versionid").val("");
                    $("#fileupload-package").val("");
                    $("#fileupload-game_name").val("");
                    $("#location").val("");
                    $("#i-file").val("");
                    $("#version-error").text("");
                },
                error: function() {
                    alert("Tải lên thất bại!")
                }
            })
        }
    })

    // Dynamic version validation
    var authFunc = function() {
        var datas = {
            "versionId": $("#fileupload-versionid").val(),
            "package_name": $("#fileupload-package").val(),
            "game_name": $("#fileupload-game_name").val(),
        };
        $.ajax({
            url: "/fileupload",
            type: "get",
            async: true,
            dataType: "json",
            data: datas,
            success: function(response) {
                $("#version-error").text(response.msg)
            },
            error: function(response) {
                alert("Kiểm tra thất bại")
            }
        })
    };
    // $("#fileupload-versionid").blur(authFunc)
    // $("#fileupload-package").blur(authFunc)
    // $("#fileupload-game_name").blur(authFunc)

    $("#dmp_upload").on("click", function() {
        var file2 = $("#i-file2").prop('files')[0];
        console.log(file2)

        if ((file2.size === 0) || (!file2)) {
            alert("Tệp tải lên không được để trống");
            return
        } else {
            var form2 = new FormData();
            form2.append("dmpFile", file2);

            $.ajax({
                url: "/dump",
                type: "post",
                async: true,
                data: form2,
                contentType: false,
                processData: false,
                beforeSend: function(xhr) {
                    $('#progressBar2').css("display", "block")
                    $("#dmp_upload").attr("disabled", "disabled")
                },
                complete: function(xhr, status) {
                    $('#progressBar2').css("display", "none")
                    $("#dmp_upload").removeAttr("disabled")
                },
                success: function(ret) {
                    console.log(ret)
                    // var ret = JSON.parse(ret);
                    if (!ret.result) {
                        alert("Tải lên thất bại!");
                        console.log(ret.msg);
                        return;
                    }
                    alert("Tải lên thành công!");
                    $("#location2").val("");
                    $("#i-file2").val("");
                },
                error: function() {
                    alert("Tải lên thất bại!")
                }
            })
        }
    })
});