local XUiGridTalentItem = XClass(nil, "XUiGridTalentItem")
local blueColor = CS.UnityEngine.Color(30 / 255, 142 / 255, 232 / 255, 1)
local blackColor = CS.UnityEngine.Color(219 / 255, 224 / 255, 229 / 255, 1)

function XUiGridTalentItem:Ctor(ui, uiRoot)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.UiRoot = uiRoot

    XTool.InitUiObject(self)
    self.Select = self.Transform:Find("Select")
    self.IsInit = false
end

function XUiGridTalentItem:Refresh(talentConfig)
    self.TalentData = talentConfig
    self.TalentTemplate = XGuildConfig.GetGuildTalentById(self.TalentData.Id)
    self.TalentConfig = XGuildConfig.GetGuildTalentConfigById(self.TalentData.Id)
    local curTalentLevel = XDataCenter.GuildManager.GetTalentLevel(self.TalentData.Id)

    -- 初始化prefab组件, 初始化一次
    if not self.TalentPrefab and not self.IsInit then
        self.IsInit = true
        self.TalentPrefab = self.Transform:LoadPrefab(self.TalentConfig.PrefabPath)
        local uiObj = self.TalentPrefab.transform:GetComponent("UiObject")
        for i = 0, uiObj.NameList.Count - 1 do
            self[uiObj.NameList[i]] = uiObj.ObjList[i]
        end
        self.BtnGuildSkillPoint.CallBack = function() self:OnBtnTalentPointClick() end
        -- 获得所有线路
        self.AllLines = {}
        for childId, childIndex in pairs(self.TalentData.ChildNodes or {}) do
            local key = string.format("Line%d_%d", self.TalentData.IndexInMap, childIndex)
            self.AllLines[key] = {}
            local lineObj = self.Transform:Find(key)
            local imgList = lineObj.gameObject:GetComponentsInChildren(typeof(CS.UnityEngine.UI.Image))
            for i = 0, imgList.Length - 1 do
                table.insert(self.AllLines[key], imgList[i])
            end
        end
    end

    -- 是否解锁
    -- 解锁、非解锁
    local isUnlock = XDataCenter.GuildManager.IsTalentUnlock(self.TalentData.Id)
    if isUnlock then
        -- 最高级
        local pointStr = string.format("%d<color=#778999>/%d</color>", curTalentLevel, #self.TalentTemplate.CostPoint)
        if XDataCenter.GuildManager.IsTalentMaxLevel(self.TalentData.Id) then
            pointStr = "MAX"
        end
        self.TxtPointNumNormal.text = pointStr
        self.TxtPointNumPress.text = pointStr
        self.TxtPointNumDisable.text = pointStr
        self.BtnGuildSkillPoint:SetDisable(false)
    else
        local pointStr = string.format("0/%d", #self.TalentTemplate.CostPoint)
        self.TxtPointNumNormal.text = pointStr
        self.TxtPointNumPress.text = pointStr
        self.TxtPointNumDisable.text = pointStr
        self.BtnGuildSkillPoint:SetDisable(true)
    end

    self.RImgSkillIconNormal:SetRawImage(self.TalentConfig.TalentIcon)
    self.RImgSkillIconPress:SetRawImage(self.TalentConfig.TalentIcon)
    self.RImgSkillIconDisable:SetRawImage(self.TalentConfig.TalentIcon)
    self:SetSelect(self.TalentData.IsSelect)
    self:UpdateLines()
end

function XUiGridTalentItem:SetSelect(isSelect)
    self.Select.gameObject:SetActiveEx(isSelect)
end

-- 路线
function XUiGridTalentItem:UpdateLines()
    if not self.TalentData then return end
    local isUnlock = XDataCenter.GuildManager.IsTalentUnlock(self.TalentData.Id)

    local color = isUnlock and blueColor or blackColor
    for key, lines in pairs(self.AllLines) do
        for _, line in pairs(lines or {}) do
            line.color = color
        end
    end

end

function XUiGridTalentItem:OnBtnTalentPointClick()
    if not self.TalentData then return end
    local isUnlock = XDataCenter.GuildManager.IsTalentUnlock(self.TalentData.Id)
    
    self.UiRoot:OnTalentPointSelect(self.TalentData.IndexInMap)
    -- self.UiRoot:FocusTargetDelay(self.Transform)
    XLuaUiManager.Open("UiGuildSkillDetail", self.TalentData.Id, function()
        self.UiRoot:ResetTalentPointSelect()
    end)
end

return XUiGridTalentItem