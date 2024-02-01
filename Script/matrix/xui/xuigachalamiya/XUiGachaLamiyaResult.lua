---@class XUiGachaLamiyaResult : XLuaUi
local XUiGachaLamiyaResult = XLuaUiManager.Register(XLuaUi, "UiGachaLamiyaResult")

local MODE_LOOP = 1

function XUiGachaLamiyaResult:OnAwake()
    self:InitAutoScript()
end

function XUiGachaLamiyaResult:OnStart(gachaId, rewardList, backCb, background)
    local behaviour = self.GameObject:AddComponent(typeof(CS.XLuaBehaviour))
    if self.Update then
        behaviour.LuaUpdate = function()
            self:Update()
        end
    end
    self._GachaId = gachaId
    self._GachaCfg = XGachaConfigs.GetGachaCfgById(self._GachaId)
    self._ShowInterval = 0.2
    self._StartShow = false
    self._LastShowTime = 0
    self._ShowIndex = 1

    self._TarnsInterval = 0.4
    self._StartTrans = false
    self._LastTarnsTime = 0
    self._TransIndex = 1
    self._TransNum = 0
    self._GridObj = {}

    self.GridGain.gameObject:SetActive(false)
    self.PanelTrans.gameObject:SetActive(false)
    self._RewardList = rewardList
    self:SetupRewards()
    self._BackCb = backCb
    self._IsFinish = false
    self.BtnBack.gameObject.transform:SetAsLastSibling()
    self:PlayAnimation("AniResultGridGain", function()
        self:PlayAnimation("AniResultGridGainLoop")
        self.AniResultGridGainLoop.extrapolationMode = MODE_LOOP
        self._StartShow = true
    end)
    if not string.IsNilOrEmpty(background) then
        local bg = self.GameObject:FindTransform("Bg1")
        if bg then
            bg.transform:GetComponent("RawImage"):SetRawImage(background)
        end
    end
end

function XUiGachaLamiyaResult:OnEnable()
    XUiHelper.PopupFirstGet()
end

function XUiGachaLamiyaResult:OnDisable()
    XDataCenter.AntiAddictionManager.EndDrawCardAction()
end

function XUiGachaLamiyaResult:Update()
    if self._StartShow then
        if self._ShowIndex > #self._RewardList then
            self._StartShow = false
            self._StartTrans = true
            self._LastTarnsTime = CS.UnityEngine.Time.time
        else
            if CS.UnityEngine.Time.time - self._LastShowTime > self._ShowInterval then
                self:ShowResult()
            end
        end
    elseif self._StartTrans then
        if CS.UnityEngine.Time.time - self._LastShowTime > self._ShowInterval then
            if self._TransIndex > self._TransNum then
                self._IsFinish = true
                self._StartTrans = false
                self.BtnBack.gameObject.transform:SetAsFirstSibling()
            else
                if CS.UnityEngine.Time.time - self._LastTarnsTime > self._TarnsInterval then
                    self:ShowTrans()
                end
            end
        end
    end
end

function XUiGachaLamiyaResult:InitAutoScript()
    self._SpecialSoundMap = {}
    self:AutoAddListener()
end

function XUiGachaLamiyaResult:GetAutoKey(uiNode, eventName)
    if not uiNode then
        return
    end
    return eventName .. uiNode:GetHashCode()
end

function XUiGachaLamiyaResult:RegisterListener(uiNode, eventName, func)
    local key = self:GetAutoKey(uiNode, eventName)
    if not key then
        return
    end
    local listener = self._AutoCreateListeners[key]
    if listener ~= nil then
        uiNode[eventName]:RemoveListener(listener)
    end

    if func ~= nil then
        if type(func) ~= "function" then
            XLog.Error("XUiGachaLamiyaResult:RegisterListener函数错误, 参数func需要是function类型, func的类型是" .. type(func))
        end

        listener = function(...)
            XSoundManager.PlayBtnMusic(self._SpecialSoundMap[key], eventName)
            func(self, ...)
        end

        uiNode[eventName]:AddListener(listener)
        self._AutoCreateListeners[key] = listener
    end
end

function XUiGachaLamiyaResult:AutoAddListener()
    self._AutoCreateListeners = {}
    self:RegisterClickEvent(self.BtnBack, self.OnBtnBackClick)
end

function XUiGachaLamiyaResult:OnBtnBackClick()
    if self._IsFinish then
        XUiHelper.StopAnimation(self, "AniResultGridGainLoop")
        if self._BackCb then
            self._BackCb()
        end
        self:Close()
    end
end

function XUiGachaLamiyaResult:SetupRewards()
    for i = 1, #self._RewardList do
        local ui = CS.UnityEngine.Object.Instantiate(self.GridGain)
        ---@type XUiGridCommon
        local grid = XUiGridCommon.New(self, ui)
        grid:SetCustomItemTip(function(data, hideSkipBtn, rootUiName, lackNum)
            XLuaUiManager.Open("UiGachaLamiyaTip", data, hideSkipBtn, rootUiName, lackNum)
        end)
        grid.Transform:SetParent(self.PanelGainList, false)
        --被转化物品
        if self._RewardList[i].ConvertFrom ~= 0 then
            self._TransNum = self._TransNum + 1
            grid:Refresh(self._RewardList[i].ConvertFrom)
        else
            grid:Refresh(self._RewardList[i])
        end
        table.insert(self._GridObj, grid)
        grid.GameObject:SetActive(false)
    end
end

function XUiGachaLamiyaResult:ShowResult()
    self._GridObj[self._ShowIndex].GameObject:SetActive(true)
    self._GridObj[self._ShowIndex].GameObject:PlayTimelineAnimation()
    CS.XAudioManager.PlaySound(XSoundManager.UiBasicsMusic.UiDrawCard_Reward_Normal)
    self._LastShowTime = CS.UnityEngine.Time.time
    self._ShowIndex = self._ShowIndex + 1
end

--已经拥有的角色转换碎片过程
function XUiGachaLamiyaResult:ShowTrans()
    local count = 0
    for i = 1, #self._RewardList do
        if self._RewardList[i].ConvertFrom ~= 0 then
            count = count + 1
            if count == self._TransIndex then
                self._GridObj[i]:Refresh(self._RewardList[i])
                local tempTransEffect = CS.UnityEngine.Object.Instantiate(self.PanelTrans)
                tempTransEffect.transform:SetParent(self.PanelContent, false)
                tempTransEffect.gameObject:SetActive(true)
                tempTransEffect.transform.localPosition = self._GridObj[i].GameObject.transform.localPosition + self.PanelGainList.transform.localPosition
                CS.XAudioManager.PlaySound(XSoundManager.UiBasicsMusic.UiDrawCard_Reward_Suipian)
            end
        end
    end
    self._LastTarnsTime = CS.UnityEngine.Time.time
    self._TransIndex = self._TransIndex + 1
end

return XUiGachaLamiyaResult