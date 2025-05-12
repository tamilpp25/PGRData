--- 公会战5.0新增驻守玩法的代理组件，用于封装驻守系统玩法在XGuildWarAgency上的接口
---@class XGarrisonAgencyCom
---@field _OwnerAgency XGuildWarAgency
---@field _OwnerModel XGuildWarModel
local XGarrisonAgencyCom = XClass(nil, 'XGarrisonAgencyCom')

function XGarrisonAgencyCom:Init(ownerAgency, ownerModel)
    self._OwnerAgency = ownerAgency
    self._OwnerModel = ownerModel
end

function XGarrisonAgencyCom:Release()
    self._OwnerAgency = nil
    self._OwnerModel = nil
end

--- 选择驻守的资源点
function XGarrisonAgencyCom:SelectDefenseNodeRequest(nodeId, cb)
    XNetwork.Call("XGuildWarSelectDefenseNodeRequest",{ NodeId = nodeId },function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
        end
        if cb then
            cb(res.Code == XCode.Success)
        end
    end)
end

return XGarrisonAgencyCom