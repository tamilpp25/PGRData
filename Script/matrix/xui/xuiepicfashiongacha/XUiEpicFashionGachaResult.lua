local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
local XUiEpicFashionGachaResult = XLuaUiManager.Register(XLuaUi, "UiEpicFashionGachaResult")

local MODE_LOOP = 1

function XUiEpicFashionGachaResult:OnAwake()
    self:InitAutoScript()
end

function XUiEpicFashionGachaResult:OnStart(gachaId, rewardList, backCb, background)
    local behaviour = self.GameObject:AddComponent(typeof(CS.XLuaBehaviour))
    if self.Update then
        behaviour.LuaUpdate = function() self:Update() end
    end
    self.GachaId = gachaId
    self.GachaCfg = XGachaConfigs.GetGachaCfgById(self.GachaId)
    self.ShowInterval = 0.2
    self.StartShow = false
    self.LastShowTime = 0
    self.ShowIndex = 1

    self.TarnsInterval = 0.4
    self.StartTrans = false
    self.LastTarnsTime = 0
    self.TransIndex = 1
    self.TransNum = 0
    self.GridObj = {}

    self.GridGain.gameObject:SetActive(false)
    self.PanelTrans.gameObject:SetActive(false)
    self.RewardList = rewardList
    self:SetupRewards()
    self.BackCb = backCb
    self.IsFinish = false
    self.BtnBack.gameObject.transform:SetAsLastSibling()
    self:PlayAnimation("AniResultGridGain", function()
        self:PlayAnimation("AniResultGridGainLoop")
        self.AniResultGridGainLoop.extrapolationMode = MODE_LOOP
        self.StartShow = true
    end)
    if not string.IsNilOrEmpty(background) then
        local bg = self.GameObject:FindTransform("Bg1")
        if bg then
            bg.transform:GetComponent("RawImage"):SetRawImage(background)
        end
    end
end

function XUiEpicFashionGachaResult:Update()
    if self.StartShow then
        if self.ShowIndex > #self.RewardList then
            self.StartShow = false
            self.StartTrans = true
            self.LastTarnsTime = CS.UnityEngine.Time.time
        else
            if CS.UnityEngine.Time.time - self.LastShowTime > self.ShowInterval then
                self:ShowResult()
            end
        end
    elseif self.StartTrans then
        if CS.UnityEngine.Time.time - self.LastShowTime > self.ShowInterval then
            if self.TransIndex > self.TransNum then
                self.IsFinish = true
                self.StartTrans = false
                self.BtnBack.gameObject.transform:SetAsFirstSibling()
            else
                if CS.UnityEngine.Time.time - self.LastTarnsTime > self.TarnsInterval then
                    self:ShowTrans()
                end
            end
        end
    end
end

function XUiEpicFashionGachaResult:OnEnable()
    XUiHelper.PopupFirstGet()
end

function XUiEpicFashionGachaResult:OnDisable()
    XDataCenter.AntiAddictionManager.EndDrawCardAction()
end

function XUiEpicFashionGachaResult:InitAutoScript()
    self.SpecialSoundMap = {}
    self:AutoAddListener()
end

function XUiEpicFashionGachaResult:GetAutoKey(uiNode, eventName)
    if not uiNode then
        return
    end
    return eventName .. uiNode:GetHashCode()
end

function XUiEpicFashionGachaResult:RegisterListener(uiNode, eventName, func)
    local key = self:GetAutoKey(uiNode, eventName)
    if not key then
        return
    end
    local listener = self.AutoCreateListeners[key]
    if listener ~= nil then
        uiNode[eventName]:RemoveListener(listener)
    end

    if func ~= nil then
        if type(func) ~= "function" then
            XLog.Error("XUiEpicFashionGachaResult:RegisterListener函数错误, 参数func需要是function类型, func的类型是" .. type(func))
        end

        listener = function(...)
            XLuaAudioManager.PlayBtnMusic(self.SpecialSoundMap[key], eventName)
            func(self, ...)
        end

        uiNode[eventName]:AddListener(listener)
        self.AutoCreateListeners[key] = listener
    end
end

function XUiEpicFashionGachaResult:AutoAddListener()
    self.AutoCreateListeners = {}
    self:RegisterClickEvent(self.BtnBack, self.OnBtnBackClick)
end

function XUiEpicFashionGachaResult:OnBtnBackClick()
    if self.IsFinish then
        XUiHelper.StopAnimation(self, "AniResultGridGainLoop")
        if self.BackCb then
            self.BackCb()
        end
        self:Close()
    end
end

function XUiEpicFashionGachaResult:SetupRewards()
    for i = 1, #self.RewardList do
        local ui = CS.UnityEngine.Object.Instantiate(self.GridGain)
        local grid = XUiGridCommon.New(self, ui)
        grid.Transform:SetParent(self.PanelGainList, false)
        --被转化物品
        if self.RewardList[i].ConvertFrom ~= 0 then
            self.TransNum = self.TransNum + 1
            grid:Refresh(self.RewardList[i].ConvertFrom)
        else
            grid:Refresh(self.RewardList[i])
        end
        table.insert(self.GridObj, grid)
        grid.GameObject:SetActive(false)
    end
end

function XUiEpicFashionGachaResult:ShowResult()
    self.GridObj[self.ShowIndex].GameObject:SetActive(true)
    self.GridObj[self.ShowIndex].GameObject:PlayTimelineAnimation()
    XLuaAudioManager.PlayAudioByType(XLuaAudioManager.SoundType.SFX, XLuaAudioManager.UiBasicsMusic.UiDrawCard_Reward_Normal)
    self.LastShowTime = CS.UnityEngine.Time.time
    self.ShowIndex = self.ShowIndex + 1
end

--已经拥有的角色转换碎片过程
function XUiEpicFashionGachaResult:ShowTrans()
    local count = 0
    for i = 1, #self.RewardList do
        if self.RewardList[i].ConvertFrom ~= 0 then
            count = count + 1
            if count == self.TransIndex then
                self.GridObj[i]:Refresh(self.RewardList[i])
                local tempTransEffect = CS.UnityEngine.Object.Instantiate(self.PanelTrans)
                tempTransEffect.transform:SetParent(self.PanelContent, false)
                tempTransEffect.gameObject:SetActive(true)
                tempTransEffect.transform.localPosition = self.GridObj[i].GameObject.transform.localPosition + self.PanelGainList.transform.localPosition
                XLuaAudioManager.PlayAudioByType(XLuaAudioManager.SoundType.SFX, XLuaAudioManager.UiBasicsMusic.UiDrawCard_Reward_Suipian)
            end
        end
    end
    self.LastTarnsTime = CS.UnityEngine.Time.time
    self.TransIndex = self.TransIndex + 1
end