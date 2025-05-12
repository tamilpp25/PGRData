---@class XUiMainLine2DetailAchievement:XLuaUi
---@field private _Control XMainLine2Control
local XUiMainLine2DetailAchievement = XLuaUiManager.Register(XLuaUi, "UiMainLine2DetailAchievement")

function XUiMainLine2DetailAchievement:OnAwake()
    self.GridAchievement.gameObject:SetActiveEx(false)
    self:RegisterUiEvents()
    self.AchievementUiObjs = {}
end

function XUiMainLine2DetailAchievement:OnStart(stageId)
    self.StageId = stageId
end

function XUiMainLine2DetailAchievement:OnEnable()
    self:Refresh()
end

function XUiMainLine2DetailAchievement:RegisterUiEvents()
    self:RegisterClickEvent(self.BtnCloseBg, self.OnBtnCloseClick)
end

function XUiMainLine2DetailAchievement:OnBtnCloseClick()
    self:Close()
end

function XUiMainLine2DetailAchievement:Refresh()
    self:RefreshAchievements()
end

-- 刷新成就列表
function XUiMainLine2DetailAchievement:RefreshAchievements()-- 获取所有关卡的成就
    local achieveInfos = self._Control:GetStagesAchievementInfos(self.StageId, nil, false)

    -- 无成就时不显示
    local isShow = #achieveInfos > 0
    if not isShow then return end

    -- 刷新显示
    for i, info in ipairs(achieveInfos) do
        local uiObj = self.AchievementUiObjs[i]
        if not uiObj then
            local go = CS.UnityEngine.Object.Instantiate(self.GridAchievement.gameObject, self.GridAchievement.transform.parent)
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
        local isHideSpecial = info.Type == XEnumConst.MAINLINE2.ACHIEVEMENT_TYPE.HIDE
        
        uiObj:GetObject("RImgNormalOn").gameObject:SetActiveEx(isNormal)
        uiObj:GetObject("RImgNormalOff").gameObject:SetActiveEx(isNormal)
        uiObj:GetObject("RImgSpecialOn").gameObject:SetActiveEx(isSpecial)
        uiObj:GetObject("RImgSpecialOff").gameObject:SetActiveEx(isSpecial)

        local rImgRealHideOn = uiObj:GetObject("RImgRealHideOn")
        local rImgRealHideOff = uiObj:GetObject("RImgRealHideOff")
        local tagRealHide = uiObj:GetObject("TagRealHide")
        
        if rImgRealHideOn then
            rImgRealHideOn.gameObject:SetActiveEx(isHideSpecial)
        end

        if rImgRealHideOff then
            rImgRealHideOff.gameObject:SetActiveEx(isHideSpecial)
        end

        if tagRealHide then
            tagRealHide.gameObject:SetActiveEx(isHideSpecial)
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
            txtDescOff.gameObject:SetActiveEx(not string.IsNilOrEmpty(info.BriefDesc))
        end

        ::CONTINUE::
    end
end

return XUiMainLine2DetailAchievement