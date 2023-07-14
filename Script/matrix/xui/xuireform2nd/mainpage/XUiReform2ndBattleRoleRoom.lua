--######################## XUiReform2ndChildPanel ########################
local XUiReform2ndChildPanel = XClass(nil, "XUiReform2ndChildPanel")

function XUiReform2ndChildPanel:Ctor(ui)
    XUiHelper.InitUiClass(self, ui)

    self.BtnChar1.gameObject:SetActiveEx(false)
    self.BtnChar2.gameObject:SetActiveEx(false)
    self.BtnChar3.gameObject:SetActiveEx(false)
end

function XUiReform2ndChildPanel:SetData(stageId)
    local stage = XDataCenter.Reform2ndManager.GetStage(stageId)
    local star = XDataCenter.Reform2ndManager.GetStarByPressure(stage:GetPressure(), stageId)

    self.TxtRecommendScore.text = XUiHelper.GetText("ReformRoleRoomStar", star)
    self.TxtScore.text = XUiHelper.GetText("ReformRoleRoomPressure", stage:GetPressure())
end

--######################## XUiReform2ndBattleRoleRoom ########################
local XUiBattleRoleRoomDefaultProxy = require("XUi/XUiNewRoomSingle/XUiBattleRoleRoomDefaultProxy")
local XUiReform2ndBattleRoleRoom = XClass(XUiBattleRoleRoomDefaultProxy, "XUiReform2ndBattleRoleRoom")

function XUiReform2ndBattleRoleRoom:GetRoleDetailProxy()
    return require("XUi/XUiReform2nd/MainPage/XUiReform2ndBattleRoomRoleDetail")
end

function XUiReform2ndBattleRoleRoom:GetAutoCloseInfo()
    local endTime = XDataCenter.Reform2ndManager.GetActivityEndTime()
    return true, endTime, function(isClose)
        if isClose then
            XDataCenter.Reform2ndManager.HandleActivityEndTime()
        end
    end
end

-- 获取子面板数据，主要用来增加编队界面自身玩法信息，就不用污染通用的预制体
--[[
    return : {
        assetPath : 资源路径
        proxy : 子面板代理
        proxyArgs : 子面板SetData传入的参数列表
    }
]]
function XUiReform2ndBattleRoleRoom:GetChildPanelData()
    return {
        assetPath = XUiConfigs.GetComponentUrl("PanelReformBattleRoom"),
        proxy = XUiReform2ndChildPanel,
        proxyArgs = { "StageId" }
    }
end

return XUiReform2ndBattleRoleRoom