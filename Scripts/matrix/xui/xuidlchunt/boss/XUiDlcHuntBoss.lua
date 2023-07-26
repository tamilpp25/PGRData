local XUiPanelRoleModel = require("XUi/XUiCharacter/XUiPanelRoleModel")
local XViewModelDlcHuntChapter = require("XEntity/XDlcHunt/XViewModel/XViewModelDlcHuntChapter")
local XUiDlcHuntChapterGrid = require("XUi/XUiDlcHunt/Boss/XUiDlcHuntChapterGrid")
local XUiDlcHuntUtil = require("XUi/XUiDlcHunt/XUiDlcHuntUtil")

---@class XUiDlcHuntBoss:XLuaUi
local XUiDlcHuntBoss = XLuaUiManager.Register(XLuaUi, "UiDlcHuntBoss")

function XUiDlcHuntBoss:Ctor()
    ---@type XViewModelDlcHuntChapter
    self._ViewModel = XViewModelDlcHuntChapter.New()
    self._UiChapterList = {}
end

function XUiDlcHuntBoss:OnAwake()
    self:BindExitBtns()
    -- uiDlcHunt hide panelAsset
    self.PanelAsset.gameObject:SetActiveEx(false)
    XUiHelper.RegisterClickEvent(self, self.BtnDlcYellow, self.OnClickConfirm)
end

function XUiDlcHuntBoss:OnEnable()
    local chapterList = self._ViewModel:GetAllChapters()
    XUiDlcHuntUtil.UpdateDynamicItem(self._UiChapterList, chapterList, self.GridBoss, XUiDlcHuntChapterGrid)
    local buttonList = {}
    for i = 1, #self._UiChapterList do
        buttonList[i] = self._UiChapterList[i]:GetButton()
    end
    self.PanelBoss:Init(buttonList, function(index)
        local chapter = chapterList[index]
        local isUnlock, reason = chapter:IsUnlock()
        if not isUnlock then
            if reason == XDlcHuntWorldConfig.CHAPTER_LOCK_STATE.LOCK_FOR_TIME then
                -- 挑战开启时间
                local beginTime = chapter:GetChapterUnlockTime()
                local timeFormat = "yyyy-MM-dd HH:mm"
                local timeStr = XTime.TimestampToGameDateTimeString(beginTime, timeFormat)
                XUiManager.TipMsg(XUiHelper.GetText("DlcHuntWorldLock4Time", timeStr))

                -- 前置关卡未解锁
            elseif reason == XDlcHuntWorldConfig.CHAPTER_LOCK_STATE.LOCK_FOR_FRONT_WORLD_NOT_PASS then
                local preWorldId = chapter:GetChapterPreWorldId()
                local preWorld = chapter:GetWorld(preWorldId)
                if preWorld then
                    local name = preWorld:GetName()
                    XUiManager.TipMsg(XUiHelper.GetText("DlcHuntWorldLock4PreWorld", name))
                end
            end
            return
        end
        local oldChapter = self._ViewModel:GetChapter()
        self._ViewModel:SetChapter(chapter)
        if oldChapter ~= chapter then
            self:UpdateInfo()
            XEventManager.DispatchEvent(XEventId.EVENT_DLC_HUNT_BOSS_SELECT_CHAPTER_UPDATE, chapter)
        end
    end)

    local selectedIndex = false
    local chapterSelected = self._ViewModel:GetChapter()
    if chapterSelected then
        for i = #chapterList, 1, -1 do
            local chapter = chapterList[i]
            if chapter == chapterSelected then
                selectedIndex = i
                break
            end
        end
    else
        for i = #chapterList, 1, -1 do
            local chapter = chapterList[i]
            if chapter:IsUnlock() then
                selectedIndex = i
                break
            end
        end
    end
    if selectedIndex then
        self.PanelBoss:SelectIndex(selectedIndex)
    end
end

function XUiDlcHuntBoss:OnClickConfirm()
    local chapter = self._ViewModel:GetChapter()
    self.ParentUi:DlcOpenChildUi("UiDlcHuntBossLevel", chapter)
end

function XUiDlcHuntBoss:UpdateInfo()
    local chapter = self._ViewModel:GetChapter()
    self.Text.text = chapter:GetName()
    self.Text2.text = chapter:GetDesc()
    local model1 = chapter:GetModel()
    local model2 = chapter:GetModel2()
    self.ParentUi:UpdateBossModel(model1, model2)
end

function XUiDlcHuntBoss:Close()
    self.ParentUi:DlcCloseChildUi(self.Name)
end

return XUiDlcHuntBoss