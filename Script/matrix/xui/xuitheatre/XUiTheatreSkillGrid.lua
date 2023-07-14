local XUiTheatreSkillGrid = XClass(nil, "XUiTheatreSkillGrid")

function XUiTheatreSkillGrid:Ctor(ui)
    XUiHelper.InitUiClass(self, ui)
    self.TokenManager = XDataCenter.TheatreManager.GetTokenManager()
end

-- skill : XAdventureSkill
-- isShowActiveSkill: 是否强制显示激活的状态
-- gridIndex：格子下标
function XUiTheatreSkillGrid:SetData(skill, isShowActiveSkill, gridIndex)
    if not skill and not gridIndex then
        return self
    end

    local isCore = skill and skill:GetSkillType() == XTheatreConfigs.SkillType.Core or false

    local icon = skill and skill:GetIcon() or XTheatreConfigs.GetSkillPosIcon(gridIndex)
    if self.RImgIcon and icon then
        self.RImgIcon:SetRawImage(icon)
    end
    --未解锁状态的技能图标
    if self.RImgIconType and icon then
        self.RImgIconType:SetRawImage(icon)
    end

    if self.TxtLevel then
        self.TxtLevel.text = isCore and skill:GetCurrentLevel() or ""
    end

    if isCore then
        if self.ImgLvBg then
            self.ImgLvBg:SetSprite(skill:GetLevelQualityIcon())
        end
        if self.RImgBg then
            self.RImgBg:SetRawImage(skill:GetQualityIcon())
        end
    end

    -- 核心技能才会显示品质
    if self.ImgLvBg then
        self.ImgLvBg.gameObject:SetActiveEx(isCore)
    end
    if self.RImgBg then
        self.RImgBg.gameObject:SetActiveEx(isCore)
    end

    -- 激活技能显隐
    if skill then
        local theatreSkillId = skill:GetId()
        local isActiveSkill = isShowActiveSkill or self.TokenManager:IsActiveSkill(theatreSkillId)
        if self.Normal then
            self.Normal.gameObject:SetActiveEx(isActiveSkill)
        end
        if self.None then
            self.None.gameObject:SetActiveEx(not isActiveSkill)
        end
    end
    return self
end

function XUiTheatreSkillGrid:SetLevel(value)
    if self.TxtLevel then
        self.TxtLevel.text = value
    end
end

function XUiTheatreSkillGrid:SetIcon(icon)
    if self.RImgIcon then
        self.RImgIcon:SetRawImage(icon)
    end
end

return XUiTheatreSkillGrid