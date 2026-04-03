function a_method(self, file, _id) {
    $(self).text('Đang phân tích...');
    $(self).addClass("disabled");
    $.ajax({
        url: '/db/manualanalysis',
        type: 'get',
        dataType: 'json',
        async: true,
        data: {"file": file, "_id": _id},
        success: function (data) {
            $(self).text('Phân tích');
            $(self).removeClass("disabled");
            if (data.ret) {
                if (file == "dmp") {
                    $('#dmptable').bootstrapTable("refresh")
                } else {
                    $('#sotable').bootstrapTable("refresh")
                }
                alert("Đã phân tích xong")
            } else {
                alert(data.error)
            }
        },
        error: function (result) {
            $(self).text('Phân tích');
            $(self).removeClass("disabled");
            alert("fail!");
        },
    })
}

$(function () {
    $("div.sidebar ul.nav a").each(function(){
        $(this).removeClass("s-active")
    });
    $("#my-tables-show").addClass("s-active");
    initDatetimePicker()

    var queryParams = function(params) {
        params.date_start = $("#index-start").val();
        if (params.date_start) {
            params.date_start += " 0:0:0"
        }
        params.date_end = $("#index-end").val();
        if (params.date_end) {
            params.date_end += " 23:59:59"
        }
        if (params.order == "desc") {
            params.order = -1
        }
        else if (params.order == "asc") {
            params.order = 1
        }
        return params;
    };
    var responseHandler = function(res) {
        return {
            "total": res.total,
            "rows": res.rows,
            "offset": res.offset,
            "limit": res.limit
        }
    };

    $('#stacktable').bootstrapTable({
        url: '/db/table_views/dmpst_db',
        method: 'post',
        contentType:"application/json",
        dataType: "json",
        striped: true,
        pagination: true,
        sidePagination: "server",
        pageNumber: 1,
        pageSize: 10,
        pageList: [10, 20, 30, 40, 50],
        search: true,
        showColumns: true,
        showRefresh: true,
        sortName: "lasttime",
        sortOrder: "desc",
        responseHandler: responseHandler,
        queryParams: queryParams,

        columns: [
            {field: 'id', title: 'Mã DB', align: 'center'},
            {field: 'feature', title: 'Mô tả', align: 'center',
                formatter: function(value, row, index) {
                    return '<a href="/crashinfo?_id='+encodeURIComponent(row.id)+'&type=-1" target="_blank">' + value + '</a>'
                }
            },
            {field: 'report_version', title: 'Phiên bản báo lỗi', align: 'center',},
            {field: 'count', title: 'Tổng số crash', align: 'center',},
            {field: 'firsttime', title: 'Thời gian báo đầu tiên', align: 'center',},
            {field: 'lasttime', title: 'Thời gian báo gần nhất', align: 'center',},
            {field: 'status', title: 'Trạng thái', align: 'center',},
        ],
    });
    $('#sotable').bootstrapTable({
        url: '/db/table_views/upfile_db',
        method: 'post',
        dataType: "json",
        striped: true,
        pagination: true,
        sidePagination: "server",
        pageNumber: 1,
        pageSize: 10,
        pageList: [10, 20, 30, 40, 50],
        search: true,
        // strictSearch: false,
        showColumns: true,
        showRefresh: true,
        sortName: "ctime",
        sortOrder: "desc",
        responseHandler: responseHandler,
        queryParams: queryParams,

        columns: [
            {field: 'id', title: 'Mã DB', align: 'center'},
            {field: 'version', title: 'Phiên bản', align: 'center',},
            {field: 'package_name', title: 'Tên gói', align: 'center',},
            {field: 'time', title: 'Thời gian tải lên', align: 'center',},
            {field: 'name', title: 'Tên tệp đã tải', align: 'center',},
            {field: 'status', title: 'Trạng thái', align: 'center',},
            {field: 'symbol_nums', title: 'Mã tệp symbol', align: 'center',},
            {field: 'op', title: 'Thao tác', align: 'center',
                formatter: function (value, row, index) {
                    return '<a href="#" class="btn btn-default" onclick="a_method(this, \'so\', \'" + row.id + "\')">Phân tích</a>'
                }
            }],
    });
    $('#dmptable').bootstrapTable({
        url: '/db/table_views/dmp_db',
        method: 'post',
        dataType: "json",
        pagination: true,
        singleSelect: false,
        search: true,
        toolbar: '#toolbar',
        striped: true,
        cache: false,
        pageNumber: 1,
        pageSize: 10,
        pageList: [10, 20, 50, 100],
        strictSearch: false,
        showColumns: true,
        showRefresh: true,
        minimumCountColumns: 2,
        sidePagination: "server",
        // sortable: true,
        sortName: "report_time",
        sortOrder: "desc",
        responseHandler: responseHandler,
        // queryParamsType: "undefined",
        queryParams: queryParams,
        contentType: "application/json",

        columns: [
            {field: 'id', title: 'Mã DB', align: 'center'},
            {field: 'feature', title: 'Mô tả', align: 'center',},
            {field: 'report_time', title: 'Thời điểm crash', align: 'center',},
            {field: 'file_name', title: 'Tên tệp dmp', align: 'center',},
            {field: 'status', title: 'Trạng thái', align: 'center',},
            {field: 'symbol_nums', title: 'Tệp symbol đã dùng', align: 'center',},
            {field: 'id', title: 'Thao tác', align: 'center',
                formatter: function (value, row, index) {
                    var e = '<a href="#" class="btn btn-default" onclick="a_method(this, \'dmp\', \'" + row.id + "\')">Phân tích</a>';  // row.id is each row id
                    // var d = '<a href="#" mce_href="#" onclick="del(\'' + row.id + '\')">View</a> ';
                    return e;
                }
            },
        ],
    });
    $('#exceptiontable').bootstrapTable({
        url: '/db/table_views/exst_db',
        method: 'post',
        dataType: "json",
        striped: true,
        pagination: true,
        sidePagination: "server",
        pageNumber: 1,
        pageSize: 10,
        pageList: [10, 20, 30, 40, 50],
        search: true,
        strictSearch: false,
        showColumns: true,
        showRefresh: true,
        sortName: "lasttime",
        sortOrder: "desc",
        responseHandler: responseHandler,
        queryParams: queryParams,
        // classes: "table table-hover table-no-bordered",

       columns: [
            {field: 'id', title: 'Mã DB', align: 'center'},
            {field: 'feature', title: 'Mô tả', align: 'center',
                formatter: function(value, row, index) {
                    return '<a href="/crashinfo?_id=' + encodeURIComponent(row.id) + '&type=1" target="_blank">' + value + '</a>'
                }
            },
            {field: 'report_version', title: 'Phiên bản báo lỗi', align: 'center',},
            {field: 'count', title: 'Tổng số lần báo', align: 'center'},
            {field: 'firsttime', title: 'Thời gian báo đầu tiên', align: 'center',},
            {field: 'lasttime', title: 'Tên tệp báo gần nhất', align: 'center',},
            {field: 'status', title: 'Trạng thái', align: 'center',},
        ],
    });
    $('#exceptionstable').bootstrapTable({
        url: '/db/table_views/exre_db',
        method: 'post',
        dataType: "json",
        striped: true,
        pagination: true,
        sidePagination: "server",
        pageNumber: 1,
        pageSize: 10,
        pageList: [10, 20, 30, 40, 50],
        search: true,
        strictSearch: false,
        showColumns: true,
        showRefresh: true,
        sortName: "report_time",
        sortOrder: "desc",
        responseHandler: responseHandler,
        queryParams: queryParams,
        // classes: "table table-hover table-no-bordered",

       columns: [
            {field: 'id', title: 'Mã DB', align: 'center'},
            {field: 'feature', title: 'Mô tả', align: 'center',},
            {field: 'version', title: 'Phiên bản', align: 'center',},
            {field: 'package_name', title: 'Tên gói', align: 'center',},
            {field: 'report_time', title: 'Thời gian báo lỗi', align: 'center',},
            {field: 'phone_name', title: 'Mẫu điện thoại', align: 'center',},
            {field: 'phone_sys', title: 'Hệ điều hành', align: 'center',},
            {field: 'status', title: 'Trạng thái', align: 'center',},
        ],
    });
    $(document).keyup(function(e) {
        if (e.keyCode === 13) {
            $('#stacktable').bootstrapTable("refresh");
            $('#sotable').bootstrapTable("refresh");
            $('#dmptable').bootstrapTable("refresh");
            $('#exceptiontable').bootstrapTable("refresh");
            $('#exceptionstable').bootstrapTable("refresh");
        }
    })
})