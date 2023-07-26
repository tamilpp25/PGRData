XAssistManagerCreator = function()
    local XAssistManager = {}

    XAssistManager.AssistType = {
        Friend = 1,
        Legion = 2,
        Passer = 3,
        Robot = 4
    }

    local METHOD_NAME = {
        GetPasser = "GetPasser",
        ChangeAssistCharacterId = "ChangeAssistCharIdRequest",
    }

    local AssistPlayerData = {}

    function XAssistManager.NotifyAssistData(data)
        XAssistManager.InitAssistData(data.AssistData)
    end

    function XAssistManager.InitAssistData(assistData)
        if assistData == nil then
            return
        end
        AssistPlayerData = assistData
    end

    function XAssistManager.GetAssistCharacterId()
        return AssistPlayerData.AssistCharacterId
    end

    function XAssistManager.ChangeAssistCharacterId(id, cb)
        XNetwork.Call(METHOD_NAME.ChangeAssistCharacterId, { AssistCharId = id },
        function(response)
            if response.Code == XCode.Success then
                AssistPlayerData.AssistCharacterId = id
                cb(response.Code)
            else
                XUiManager.TipCode(response.Code)
            end
        end)
    end

    return XAssistManager
end

XRpc.NotifyAssistData = function(data)
    XDataCenter.AssistManager.NotifyAssistData(data)
end