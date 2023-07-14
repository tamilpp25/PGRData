local GRID_CONDITION_MAX_COUNT = 3

--萌战通用角色格子
local XUiGridHelper = XClass(nil, "XUiGridHelper")

function XUiGridHelper:Ctor(ui, clickCb)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)

    self.ClickCallback = clickCb    --点击回调

    self:InitAddListener()
end

function XUiGridHelper:InitAddListener()
    if self.BtnOccupy then
        XUiHelper.RegisterClickEvent(self, self.BtnOccupy, self.OnClick)
    end
    if self.BtnJoin then
        XUiHelper.RegisterClickEvent(self, self.BtnJoin, self.OnClick)
    end
end

function XUiGridHelper:OnClick()
    if self.ClickCallback then
        self.ClickCallback(self.HelperId)
    end
end

function XUiGridHelper:Refresh(data)
    local helperId = data.HelperId  --MoeWarPreparationHelper表的Id
    local stageId = data.StageId    --MoeWarPreparationStage表的Id
    local isShowMoodUpLimit = data.IsShowMoodUpLimit    --是否显示心情值上限
    self.HelperId = helperId
    self.StageId = stageId

    local isHaveHelper = XTool.IsNumberValid(helperId)
    --无角色时显示的按钮
    if self.BtnOccupyMember then
        self.BtnOccupyMember.gameObject:SetActiveEx(not isHaveHelper)
    end
    --有角色时显示的按钮
    if self.BtnOccupy then
        self.BtnOccupy.gameObject:SetActiveEx(isHaveHelper)
    end

    if not isHaveHelper then
        return
    end

    local robotId = XMoeWarConfig.GetMoeWarPreparationHelperRobotId(helperId)
    local charId = XEntityHelper.GetCharacterIdByEntityId(robotId)
    local curMoodValue = XDataCenter.MoeWarManager.GetMoodValue(helperId)
    local moodUpLimit = XMoeWarConfig.GetPreparationHelperMoodUpLimit(helperId)
    local moodId = XMoeWarConfig.GetCharacterMoodId(curMoodValue)
    local icon
    local color = XMoeWarConfig.GetCharacterMoodColor(moodId)

    --角色头像
    if self.ImgRoleHead then
        icon = XMoeWarConfig.GetMoeWarPreparationHelperCirleIcon(helperId)
        self.ImgRoleHead:SetRawImage(icon)
    end

    --角色名字
    if self.TxtName then
        self.TxtName.text = XEntityHelper.GetCharacterLogName(charId)
    end

    --当前心情值
    if self.TxtMoodAdd then
        self.TxtMoodAdd.text = isShowMoodUpLimit and string.format("%d/%d", curMoodValue, moodUpLimit) or curMoodValue
        self.TxtMoodAdd.color = color
    end

    --当前心情值进度
    if self.ImgCurEnergy then
        self.ImgCurEnergy.fillAmount = curMoodValue / moodUpLimit
        self.ImgCurEnergy.color = color
    end

    --当前心情图标
    if self.ImgMoodIcon then
        icon = XMoeWarConfig.GetCharacterMoodIcon(moodId)
        self.ImgMoodIcon:SetSprite(icon)
    end

    --预计消耗的心情值
    if self.TxtMood then
        self.TxtMood.text = "-" .. XMoeWarConfig.GetStageCostMoodNum(stageId, helperId)
    end

    self:RefreshHelperCondition()
end

--刷新角色带有的条件
function XUiGridHelper:RefreshHelperCondition()
    local helperId = self.HelperId
    local helperLabelIds = XTool.IsNumberValid(helperId) and XMoeWarConfig.GetMoeWarPreparationHelperLabelIds(helperId) or {}
    for i = 1, GRID_CONDITION_MAX_COUNT do
        if not helperLabelIds[i] then
            if self["TagLabel" .. i] then
                self["TagLabel" .. i].gameObject:SetActiveEx(false)
            end
        else
            if self["TextTagLabel" .. i] then
                self["TextTagLabel" .. i].text = XMoeWarConfig.GetPreparationStageTagLabelById(helperLabelIds[i])
            end
            if self["TagLabel" .. i] then
                self["TagLabel" .. i].gameObject:SetActiveEx(true)
            end
        end
    end
end

--设置选中状态是否显示
function XUiGridHelper:SetImgSelectActive(isActive)
    if self.ImgSelect then
        self.ImgSelect.gameObject:SetActiveEx(isActive)
    end
end

function XUiGridHelper:GetHelperId()
    return self.HelperId
end

return XUiGridHelper