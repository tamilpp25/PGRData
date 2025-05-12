---@class XUiMainLine2Settlement:XLuaUi
---@field private _Control XMainLine2Control
local XUiMainLine2Settlement = XLuaUiManager.Register(XLuaUi, "UiMainLine2Settlement")

function XUiMainLine2Settlement:OnAwake()

    self.AchievementUiObjs = { self.GridAchievement }
    self:RegisterUiEvents()
end

function XUiMainLine2Settlement:OnStart(winData)
    self.StageId = winData.StageId
end

function XUiMainLine2Settlement:OnEnable()
    self:Refresh()
end

function XUiMainLine2Settlement:RegisterUiEvents()
    self:RegisterClickEvent(self.BtnLeave, self.OnBtnLeaveClick)
end

function XUiMainLine2Settlement:OnBtnLeaveClick()
    self:Close()
end

function XUiMainLine2Settlement:Refresh()
    self:RefreshInfo()
    self:RefreshAchievements()
    self:RefreshProgress()
end

function XUiMainLine2Settlement:RefreshInfo()
    local stageCfg = XMVCA:GetAgency(ModuleId.XFuben):GetStageCfg(self.StageId)
    local chapterId = self._Control:GetStageChapterId(self.StageId)
    local mainId = self._Control:GetChapterMainId(chapterId)
    local title = self._Control:GetMainTitle(mainId)
    local settlementBg = self._Control:GetMainSettlementBg(mainId)
    self.TxtStageName.text = title .. "-" .. tostring(stageCfg.OrderId) .. tostring(stageCfg.Name)
    self.TxtTarget.text = stageCfg.StarDesc[1]
    self.RImgStageIcon:SetRawImage(stageCfg.StoryIcon)
    if settlementBg and settlementBg ~= "" then 
        self.Bg:SetRawImage(settlementBg)
    end
end

-- 刷新成就
function XUiMainLine2Settlement:RefreshAchievements()
    -- 获取所有关卡的成就
    local achieveInfos = self._Control:GetStagesAchievementInfos(self.StageId)

    -- 无成就时不显示
    local isShow = #achieveInfos > 0
    self.PanelAchievement.gameObject:SetActiveEx(isShow)
    if not isShow then
        return
    end

    -- 刷新显示
    for i, info in ipairs(achieveInfos) do
        local uiObj = self.AchievementUiObjs[i]
        if not uiObj then
            local go = CS.UnityEngine.Object.Instantiate(self.GridAchievement.gameObject, self.PanelAchievement.transform)
            uiObj = go:GetComponent("UiObject")
            self.AchievementUiObjs[i] = uiObj
        end
        uiObj.gameObject:SetActiveEx(true)

        -- 隐藏显示
        local isHide = info.Type == XEnumConst.MAINLINE2.ACHIEVEMENT_TYPE.HIDE and not info.IsUnLock
        if isHide then
            uiObj.gameObject:SetActiveEx(false)
            goto CONTINUE
        end

        -- 图标
        local isNormal = info.Type == XEnumConst.MAINLINE2.ACHIEVEMENT_TYPE.NORMAL
        local isSpecial = info.Type == XEnumConst.MAINLINE2.ACHIEVEMENT_TYPE.SPECIAL
        local isSpecialHide = info.Type == XEnumConst.MAINLINE2.ACHIEVEMENT_TYPE.HIDE
        
        uiObj:GetObject("RImgNormalOn").gameObject:SetActiveEx(isNormal)
        uiObj:GetObject("RImgNormalOff").gameObject:SetActiveEx(isNormal)
        uiObj:GetObject("RImgSpecialOn").gameObject:SetActiveEx(isSpecial)
        uiObj:GetObject("RImgSpecialOff").gameObject:SetActiveEx(isSpecial)

        local rImgRealHideOn = uiObj:GetObject("RImgRealHideOn")
        local rImgRealHideOff = uiObj:GetObject("RImgRealHideOff")

        if rImgRealHideOn then
            rImgRealHideOn.gameObject:SetActiveEx(isSpecialHide)
        end

        if rImgRealHideOff then
            rImgRealHideOff.gameObject:SetActiveEx(isSpecialHide)
        end
        
        -- 解锁状态
        uiObj:GetObject("PanelOn").gameObject:SetActiveEx(info.IsUnLock)
        uiObj:GetObject("PanelOff").gameObject:SetActiveEx(not info.IsUnLock)
        if info.IsUnLock then 
            uiObj:GetObject("TxtNameOn").text = info.Name
            local txtDescOn = uiObj:GetObject("TxtDescOn")
            txtDescOn.text = info.Desc
            txtDescOn.gameObject:SetActiveEx(not string.IsNilOrEmpty(info.Desc))

            local txtConditionOn = uiObj:GetObject("TxtConditionOn")
            txtConditionOn.text = info.BriefDesc
            txtConditionOn.gameObject:SetActiveEx(not string.IsNilOrEmpty(info.BriefDesc))
        else
            uiObj:GetObject("TxtNameOff").text = info.Name
            local txtDescOff = uiObj:GetObject("TxtDescOff")
            txtDescOff.text = info.UndoneDesc
            txtDescOff.gameObject:SetActiveEx(not string.IsNilOrEmpty(info.UndoneDesc))
        end

        ::CONTINUE::
    end
end

-- 刷新进度
function XUiMainLine2Settlement:RefreshProgress()
    local reachCnt, allCnt = self._Control:GetStageProgress(self.StageId)
    if allCnt <= 0 or reachCnt == allCnt then
        self.TxtTargetProgress.text = ""
    else
        self.TxtTargetProgress.text = math.floor(reachCnt / allCnt * 100) .. "%"
    end

    local agency = XMVCA:GetAgency(ModuleId.XMainLine2)
    local isPass = agency:IsStagePass(self.StageId)
    self.ClearTag.gameObject:SetActiveEx(isPass)
end

return XUiMainLine2Settlement