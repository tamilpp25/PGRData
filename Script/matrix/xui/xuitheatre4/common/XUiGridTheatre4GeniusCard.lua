local XUiGridTheatre4Genius = require("XUi/XUiTheatre4/Common/XUiGridTheatre4Genius")
---@class XUiGridTheatre4GeniusCard : XUiNode
---@field private _Control XTheatre4Control
local XUiGridTheatre4GeniusCard = XClass(XUiNode, "XUiGridTheatre4GeniusCard")

function XUiGridTheatre4GeniusCard:OnStart(selectCb, yesCb)
    self.SelectCallback = selectCb
    self.YesCallback = yesCb
    XUiHelper.RegisterClickEvent(self, self.BtnClick, self.OnBtnClick)
    self._Control:RegisterClickEvent(self, self.BtnYes, self.OnBtnYesClick)
    self.ImgSelect.gameObject:SetActiveEx(false)
    self.TxtNone.gameObject:SetActiveEx(false)
    self.TxtCondition.gameObject:SetActiveEx(false)
    self.GridTag.gameObject:SetActiveEx(false)
    self.BtnYes.gameObject:SetActiveEx(false)
    ---@type UiObject[]
    self.GridTagList = {}
end

-- 获取天赋Id
function XUiGridTheatre4GeniusCard:GetTalentId()
    return self.TalentId
end

---@param id number 天赋Id
function XUiGridTheatre4GeniusCard:Refresh(id)
    if not XTool.IsNumberValid(id) then
        return
    end
    self.TalentId = id
    self:RefreshGenius()
    self:RefreshGeniusInfo()
    self:RefreshGeniusTag()
end

-- 刷新天赋
function XUiGridTheatre4GeniusCard:RefreshGenius()
    if not self.PanelGridGenius then
        ---@type XUiGridTheatre4Genius
        self.PanelGridGenius = XUiGridTheatre4Genius.New(self.GridGenius, self)
    end
    self.PanelGridGenius:Open()
    self.PanelGridGenius:Refresh(self.TalentId)
end

-- 刷新天赋信息
function XUiGridTheatre4GeniusCard:RefreshGeniusInfo()
    -- 名称
    self.TxtName.text = self._Control:GetColorTalentName(self.TalentId)
    -- 描述
    self.TxtDetail.text = self._Control:GetColorTalentDesc(self.TalentId)
    -- 累计数量 TODO
    self.TxtNum.text = 0
end

-- 刷新天赋标签
function XUiGridTheatre4GeniusCard:RefreshGeniusTag()
    local tags = self._Control:GetColorTalentTags(self.TalentId)
    local tagColors = self._Control:GetColorTalentTagBgColors(self.TalentId) or {}
    if XTool.IsTableEmpty(tags) then
        self.ListTag.gameObject:SetActiveEx(false)
        return
    end
    self.ListTag.gameObject:SetActiveEx(true)
    for i, tag in ipairs(tags) do
        local tagObj = self.GridTagList[i]
        if not tagObj then
            tagObj = XUiHelper.Instantiate(self.GridTag, self.ListTag)
            self.GridTagList[i] = tagObj
        end
        local image = tagObj.transform:GetComponent(typeof(CS.UnityEngine.UI.Image))

        tagObj.gameObject:SetActiveEx(true)
        tagObj:GetObject("Text").text = tag

        if image then
            local color = tagColors[i]

            if not string.IsNilOrEmpty(color) then
                image.color = XUiHelper.Hexcolor2Color(color)
            end
        end
    end
    for i = #tags + 1, #self.GridTagList do
        self.GridTagList[i].gameObject:SetActiveEx(false)
    end
end

-- 设置选择状态
function XUiGridTheatre4GeniusCard:SetSelect(isSelect)
    self.ImgSelect.gameObject:SetActiveEx(isSelect)
end

-- 设置按钮显示
function XUiGridTheatre4GeniusCard:SetBtnYes(isShow)
    self.BtnYes.gameObject:SetActiveEx(isShow)
end

-- 显示未获得
function XUiGridTheatre4GeniusCard:SetTxtNone(isShow)
    self.TxtNone.gameObject:SetActiveEx(isShow)
end

-- 显示条件
function XUiGridTheatre4GeniusCard:SetTxtCondition(isShow)
    self.TxtCondition.text = isShow and self._Control:GetColorTalentConditionDesc(self.TalentId) or ""
    self.TxtCondition.gameObject:SetActiveEx(isShow)
end

function XUiGridTheatre4GeniusCard:OnBtnClick()
    if self.SelectCallback then
        self.SelectCallback(self)
    end
end

function XUiGridTheatre4GeniusCard:OnBtnYesClick()
    if self.YesCallback then
        self.YesCallback(self.TalentId)
    end
end

function XUiGridTheatre4GeniusCard:SetAlpha(alpha)
    self:_InitCanvasGroup()
    if not XTool.UObjIsNil(self._CanvasGroup) then
        self._CanvasGroup.alpha = alpha
    end
end

function XUiGridTheatre4GeniusCard:_InitCanvasGroup()
    if XTool.UObjIsNil(self._CanvasGroup) then
        self._CanvasGroup = self.Transform:GetComponent(typeof(CS.UnityEngine.CanvasGroup))
    end
end

function XUiGridTheatre4GeniusCard:PlayGeniusAnimation()
    self:PlayAnimation("GridGeniusCardEnable", function()
        self:SetAlpha(1)
    end)
end

return XUiGridTheatre4GeniusCard
