include_guard()
include(timer/subtract_time)

function(start_cmakepp_timer _sct_name)
    string(TIMESTAMP "__timer__${_sct_name}_start" "%j:%H:%M:%S")
    set(
        "__timer__${_sct_name}_start"
        "${__timer__${_sct_name}_start}"
        PARENT_SCOPE
    )
endfunction()

function(stop_cmakepp_timer _sct_time _sct_name)
    string(TIMESTAMP "__timer__${_sct_name}_now" "%j:%H:%M:%S")
    _subtract_timestamps(
       _sct_dt "${__timer__${_sct_name}_now}" "${__timer__${_sct_name}_start}"
    )
    set(${_sct_time} "${_sct_dt}" PARENT_SCOPE)
endfunction()
