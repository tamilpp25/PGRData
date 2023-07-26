---@class XCharacterControl : XControl
---@field _Model XCharacterModel
local XCharacterControl = XClass(XControl, "XCharacterControl")
function XCharacterControl:OnInit()
    --初始化内部变量
end

function XCharacterControl:CharacterResetNewFlagRequest(characterIdList, cb)
    XNetwork.Call("CharacterResetNewFlagRequest", { CharacterIds = characterIdList }, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end

        if cb then
            cb()
        end
    end)
end

function XCharacterControl:AddAgencyEvent()
    --control在生命周期启动的时候需要对Agency及对外的Agency进行注册
end

function XCharacterControl:RemoveAgencyEvent()

end

function XCharacterControl:OnRelease()
end

return XCharacterControl