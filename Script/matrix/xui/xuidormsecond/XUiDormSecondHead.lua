---@class XUiDormSecondHead
local XUiDormSecondHead = XClass(XLuaBehaviour, "XUiDormSecondHead")
local MAXPERSON = 3 --宿舍内最大角色数量

function XUiDormSecondHead:Ctor(uiRoot, ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.UiRoot = uiRoot

    self.characterData = {}
    
    XTool.InitUiObject(self)
end

function XUiDormSecondHead:Init()
    XEventManager.AddEventListener(XEventId.EVENT_DORM_EXP_DETAIL_SHOW, self.OnExpDetailShow, self)
    XEventManager.AddEventListener(XEventId.EVENT_DORM_TOUCH_ENTER, self.OnTouchEnter, self)
    XEventManager.AddEventListener(XEventId.EVENT_DORM_TOUCH_HIDE, self.OnTouchHide, self)
    XEventManager.AddEventListener(XEventId.EVENT_CHARACTER_CHANGE_ROOM_CHARACTER, self.OnChangeRoomCharacter, self)
    self.OnChangeStateCb = handler(self, self.OnChangeState)
    CsXGameEventManager.Instance:RegisterEvent(XEventId.EVENT_HOME_CHARACTER_STATUS_CHANGE, self.OnChangeStateCb)

    for i=1, MAXPERSON do
        self.UiRoot:RegisterClickEvent(self["Head" .. i], function() 
            self:OnBtnHeadClick(i) 
        end)
    end

    for i=1, MAXPERSON do
        self.UiRoot:RegisterClickEvent(self["BtnTouch" .. i], function() 
            self:OnBtnTouchClick(i) 
        end)
    end
end

function XUiDormSecondHead:OnDestroy()
    XEventManager.RemoveEventListener(XEventId.EVENT_DORM_EXP_DETAIL_SHOW, self.OnExpDetailShow, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_DORM_TOUCH_ENTER, self.OnTouchEnter, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_DORM_TOUCH_HIDE, self.OnTouchHide, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_CHARACTER_CHANGE_ROOM_CHARACTER, self.OnChangeRoomCharacter, self)
    CsXGameEventManager.Instance:RemoveEvent(XEventId.EVENT_HOME_CHARACTER_STATUS_CHANGE, self.OnChangeStateCb)

    self:RemoveTimer()
end

--@region 事件处理相关

function XUiDormSecondHead:OnBtnHeadClick(i)
    local character = self.characterData[i]
    if character then
        if not XDataCenter.DormManager.IsWorking(character.CharacterId) then
            local activeCharacter = XHomeCharManager.GetActiveCharacter(character.CharacterId)
            if activeCharacter then
                --角色被点击时先处理OnPointerDown，再处理OnClick，跳过PointerDown可能会导致角色行为状态不能成功改变
                activeCharacter:OnPointerDown()
                activeCharacter:OnClick()
                --点击先默认将红点消掉
                self["Head" .. i]:ShowReddot(false)
            end
        end
    else
        local config = XDormConfig.GetDormitoryCfgById(self.dormId)
        XLuaUiManager.Open("UiDormPerson", XDormConfig.PersonType.Staff, config.SceneId, self.dormId)
    end
end

function XUiDormSecondHead:OnBtnTouchClick(i)
    local character = self.characterData[i] 
    XEventManager.DispatchEvent(XEventId.EVENT_DORM_HEAD_TOUCH, self.CharacterId)
end

--通过监听来显示抚摸按钮，因为不一定总是能抚摸
function XUiDormSecondHead:OnExpDetailShow(characterId, transform)
    local index = self:GetIndexByCharacterId(characterId)
    if index then
        --保证只出现一个抚摸按钮
        for i=1, MAXPERSON do
            self["BtnTouch" .. i].gameObject:SetActiveEx(index == i)
        end

        self:RemoveTimer()
        self.Timer = XScheduleManager.ScheduleOnce(function()
            self["BtnTouch" .. index].gameObject:SetActiveEx(false)
        end, XDormConfig.DISPPEAR_TIME)
    end
end

function XUiDormSecondHead:OnTouchEnter(characterId)
    local index = self:GetIndexByCharacterId(characterId)
    if index then
        self["BtnTouch" .. index].gameObject:SetActiveEx(false)
    end

    self.GameObject:SetActive(false)
end

function XUiDormSecondHead:OnTouchHide()
    self.GameObject:SetActive(true)
end

function XUiDormSecondHead:OnChangeState(_, args)
    local characterId = args[0]
    local index = self:GetIndexByCharacterId(characterId)
    if index then
        local head = self["Head" .. index]
        if not XTool.UObjIsNil(head) then
            head:ShowReddot(self:IsHaveCharacterEvent(characterId))
        else
            XLog.Error("DormHead is nill, characterId:" .. tostring(characterId) .. ", index:" .. tostring(index))
        end
    end
end

function XUiDormSecondHead:OnChangeRoomCharacter(characterIds)
    if self.dormId then
        self:Refresh(self.dormId)
    end
end

--@endregion

--@region 逻辑处理

function XUiDormSecondHead:Refresh(dormId)
    self.dormId = dormId
    self.characterData = self:GetCharacterData(dormId)
    
    local characterCount = #self.characterData
    local showAdd = characterCount < MAXPERSON
    local isShowAdd = false
    
    for i=1, MAXPERSON do
        local character = self.characterData[i] 
        local btn = self["Head" .. i]
        if XTool.UObjIsNil(btn) then
            goto continue
        end
        btn:ShowReddot(false)
        if character then
            btn.gameObject:SetActiveEx(true)

            local iconPath = XDormConfig.GetCharacterStyleConfigQSIconById(character.CharacterId)
            if iconPath then
                local imgHead = self["ImgHead" .. i]
                imgHead.gameObject:SetActiveEx(true)
                imgHead:SetSprite(iconPath)
            end

            btn:ShowReddot(self:IsHaveCharacterEvent(character.CharacterId))

            self["PanelWorking" .. i].gameObject:SetActiveEx(XDataCenter.DormManager.IsWorking(character.CharacterId))
            self["ImgAdd"..i].gameObject:SetActiveEx(false)
        else
            if showAdd and not isShowAdd then
                btn.gameObject:SetActiveEx(true)
                self["PanelWorking" .. i].gameObject:SetActiveEx(false)
                self["ImgHead" .. i].gameObject:SetActiveEx(false)
                self["ImgAdd"..i].gameObject:SetActiveEx(true)
                isShowAdd = true
            else
                btn.gameObject:SetActiveEx(false)
            end
        end
        ::continue::
    end
end

function XUiDormSecondHead:GetCharacterData(dormId)
    local data = XDataCenter.DormManager.GetRoomDataByRoomId(self.dormId)
    if data then
        return data:GetCharacter() or {}
    end
end

function XUiDormSecondHead:GetIndexByCharacterId(characterId)
    for i,v in ipairs(self.characterData) do
        if v.CharacterId == characterId then
            return i
        end
    end
end

function XUiDormSecondHead:RemoveTimer()
    if self.Timer then
        XScheduleManager.UnSchedule(self.Timer)
        self.Timer = nil
    end
end

function XUiDormSecondHead:IsHaveCharacterEvent(characterId)
    local eventTemp = XHomeCharManager.GetCharacterEvent(characterId, true)
    if eventTemp then
        if eventTemp.BehaviorId == XHomeBehaviorStatus.REWAWRD 
        or eventTemp.BehaviorId == XHomeBehaviorStatus.BORING 
        or eventTemp.BehaviorId == XHomeBehaviorStatus.WANTTOUCH then
            return true
        end
    end
    
    return false
end

--@endregion

return XUiDormSecondHead