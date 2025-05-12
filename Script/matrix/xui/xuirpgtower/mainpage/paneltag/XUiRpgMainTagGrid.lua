-- 兵法蓝图主页面关卡列表：关卡显示控件
local XUiRpgMainTagGrid = XClass(nil, "XUiRpgMainTagGrid")

local ColorState = 
{
    NonePass = "<color=#b2b2b2>%s</color><color=#b2b2b2>%s</color><color=#b2b2b2>%s</color>", --没有通过的
    PartiallyPassed = "<color=#FFE400>%s</color><color=#b2b2b2>%s</color><color=#b2b2b2>%s</color>", --部分通过
    AllPass = "<color=#FFE400>%s</color><color=#FFE400>%s</color><color=#FFE400>%s</color>", --全部通过
}

function XUiRpgMainTagGrid:Ctor(ui)
    XTool.InitUiObjectByUi(self, ui)
    self.Unlock = false -- 解锁
    self.Btn = self.Transform:GetComponent("XUiButton")
    self.Btn.CallBack = function () self:OnBtnClick() end
end

function XUiRpgMainTagGrid:Refresh(data)
    self.Data = data

    -- self.CurrTagStageList = XRpgTowerConfig.GetStageListByTagId(data.Id)
    self.CurrTagStageList = XDataCenter.RpgTowerManager.GetCurrActivityStageListByTagId(data.Id)
    if not self.CurrTagStageList then
        return
    end 
    -- 遍历Stage 获得解锁数据 和 进度数据
    local currProgress = 0
    for k, stageCfg in pairs(self.CurrTagStageList) do -- 只要该标签下有解锁的stage就解锁
        local rStage = XDataCenter.RpgTowerManager.GetRStageByStageId(stageCfg.StageId)
        if rStage:GetIsPass() then
            currProgress = currProgress + 1
        end
        if rStage:GetIsUnlock() then
            self.Unlock = true
        end
    end
    -- 进度 ,不同进度 文本颜色会不一样
    local colorState = ColorState.NonePass
    if currProgress == 0 then
        colorState = ColorState.NonePass
    elseif currProgress ~= 0 and currProgress ~= #self.CurrTagStageList then
        colorState = ColorState.PartiallyPassed
    elseif currProgress == #self.CurrTagStageList then
        colorState = ColorState.AllPass
    end

    self.Btn:SetNameByGroup(0, data.Name) -- 标签名
    self.Btn:SetNameByGroup(1, string.format(colorState, currProgress, "/", #self.CurrTagStageList))   -- 进度
    self.Btn:SetDisable(not self.Unlock) -- 解锁
    self.Btn:SetNameByGroup(2, self:GetCurrLockTip(true)) -- 解锁名
    self.Btn:ShowReddot(self.Unlock and currProgress < #self.CurrTagStageList) -- 红点
end

function XUiRpgMainTagGrid:GetCurrLockTip(onlyStageName)
    local stageCfg = XDataCenter.FubenManager.GetStageCfg(self.CurrTagStageList[1].StageId)
    local preStageId = stageCfg.PreStageId[1]
    if not preStageId then
        return CS.XTextManager.GetText("RpgTowerTalentLock")
    end

    local name = XDataCenter.FubenManager.GetStageCfg(preStageId).Name
    if onlyStageName then
        return name
    end

    local preTagId = XRpgTowerConfig.GetRStageCfgByStageId(preStageId).TagId
    local preTagData = XRpgTowerConfig.GetRTagConfigs()[preTagId]
    return CS.XTextManager.GetText("RpgTowerStageLock", preTagData.Name, name)
end

function XUiRpgMainTagGrid:OnBtnClick()
    if not self.Unlock then
        XUiManager.TipMsg(self:GetCurrLockTip())
        return
    end

    XLuaUiManager.Open("UiRpgTowerMain", self.Data)
end

return XUiRpgMainTagGrid