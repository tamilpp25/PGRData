---@class XUiBigWorldMessageTask : XUiNode
---@field ImgIcon UnityEngine.UI.Image
---@field TxtTips UnityEngine.UI.Text
---@field TxtTitle UnityEngine.UI.Text
---@field ImgGo UnityEngine.UI.Image
---@field ImgComplete UnityEngine.UI.Image
---@field BtnTask XUiComponent.XUiButton
local XUiBigWorldMessageTask = XClass(XUiNode, "XUiBigWorldMessageTask")

-- region 生命周期

function XUiBigWorldMessageTask:OnStart()
    self:_RegisterButtonClicks()
end

function XUiBigWorldMessageTask:OnEnable()
    self:_RegisterSchedules()
    self:_RegisterListeners()
    self:_RegisterRedPointEvents()
end

function XUiBigWorldMessageTask:OnDisable()
    self:_RemoveSchedules()
    self:_RemoveListeners()
end

function XUiBigWorldMessageTask:OnDestroy()

end

function XUiBigWorldMessageTask:OnTaskSkip()
    if self._QuestId then
        local questData = XMVCA.XBigWorldQuest:GetQuestData(self._QuestId)

        if questData and not questData:IsFinish() then
            XMVCA.XBigWorldGamePlay:GetCurrentAgency():OpenQuest(1, self._QuestId)
        end
    end
end

-- endregion

function XUiBigWorldMessageTask:Refresh(questId)
    ---@type XBigWorldQuest
    local questData = XMVCA.XBigWorldQuest:GetQuestData(questId)

    if questData then
        self.TxtTitle.text = XMVCA.XBigWorldQuest:GetQuestText(questId)
        self.ImgIcon:SetSprite(XMVCA.XBigWorldQuest:GetQuestIcon(questId))
        self.TxtTips.gameObject:SetActiveEx(false)
        self.ImgGo.gameObject:SetActiveEx(not questData:IsFinish())
        self.ImgComplete.gameObject:SetActiveEx(questData:IsFinish())
        if not questData:IsFinish() then
            self._QuestId = questId
        else
            self._QuestId = false
        end
    else
        self._QuestId = false
        self:Close()
    end
end

-- region 私有方法

function XUiBigWorldMessageTask:_RegisterButtonClicks()
    -- 在此处注册按钮事件
    XUiHelper.RegisterCommonClickEvent(self, self.BtnTask, self.OnTaskSkip)
end

function XUiBigWorldMessageTask:_RegisterSchedules()
    -- 在此处注册定时器
end

function XUiBigWorldMessageTask:_RemoveSchedules()
    -- 在此处移除定时器
end

function XUiBigWorldMessageTask:_RegisterListeners()
    -- 在此处注册事件监听
end

function XUiBigWorldMessageTask:_RemoveListeners()
    -- 在此处移除事件监听
end

function XUiBigWorldMessageTask:_RegisterRedPointEvents()
    -- 在此处注册红点事件
    -- self:AddRedPointEvent(...)
end

-- endregion

return XUiBigWorldMessageTask
