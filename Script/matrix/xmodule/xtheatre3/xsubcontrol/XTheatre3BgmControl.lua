---@class XTheatre3BgmControl : XControl
---@field _Model XTheatre3Model
local XTheatre3BgmControl = XClass(XControl, "XTheatre3BgmControl")

function XTheatre3BgmControl:OnInit()
    self:_DestroyBgmNode()
    ---@type XIResource
    self._QuantumBgmNodeResource = nil
    ---@type UnityEngine.Transform
    self._QuantumBgmNode = nil
    
    self._IsPlayBgm = false
    self._IsMainMode = false
    
    self:_InitBgmNode()
    self:AddEventListener()
end

function XTheatre3BgmControl:OnRelease()
    self:_DestroyBgmNode()
    self._QuantumBgmNode = nil
    self._QuantumBgmNodeResource = nil
    self:RemoveEventListener()
end

--region Control
---@class XTheatre3BgmNodeObjTable
---@field Bgm XAudio.XPlaySoundWithSource
---@field AnimBgmOff UnityEngine.Playables.PlayableDirector
---@field AnimBgmOn UnityEngine.Playables.PlayableDirector

function XTheatre3BgmControl:_InitBgmNode()
    local url = self._Model:GetClientConfig("QuantumBgmNodeUrl", 1)
    if string.IsNilOrEmpty(url) then
        return
    end
    self._QuantumBgmNodeResource = CS.XResourceManager.Load(url)
    if not self._QuantumBgmNodeResource then
        return
    end
    ---@type UnityEngine.Transform
    local audioManagerTran = CS.XAudioManager.AtomSource.transform
    if audioManagerTran then
        self._QuantumBgmNode = XUiHelper.Instantiate(self._QuantumBgmNodeResource.Asset, audioManagerTran)
    else
        self._QuantumBgmNode = XUiHelper.Instantiate(self._QuantumBgmNodeResource.Asset)
    end
    ---@type XTheatre3BgmNodeObjTable
    self._QuantumObjTable = {}
    XTool.InitUiObjectByUi(self._QuantumObjTable, self._QuantumBgmNode)
end

function XTheatre3BgmControl:_DestroyBgmNode()
    if self._QuantumBgmNode then
        XUiHelper.Destroy(self._QuantumBgmNode.gameObject)
    end
    if self._QuantumBgmNodeResource then
        self._QuantumBgmNodeResource:Release()
    end
    self._QuantumObjTable = nil
end

function XTheatre3BgmControl:PlayQuantumBgm(isALine)
    if not self._QuantumBgmNode then
        return
    end
    if isALine then
        self:StopQuantumBgm()
    else
        if self._QuantumObjTable.Bgm then
            self._QuantumObjTable.Bgm.gameObject:SetActiveEx(true)
        end
    end
end

function XTheatre3BgmControl:PlayQuantumBgmByChangeChapter(isALine)
    if not self._QuantumBgmNode then
        return
    end
    if isALine then
        self:_PlayQuantumBgmOffAnim()
    else
        self:_PlayQuantumBgmOnAnim()
    end
end

function XTheatre3BgmControl:StopQuantumBgm()
    if not self._QuantumBgmNode then
        return
    end
    if self._QuantumObjTable.Bgm then
        self._QuantumObjTable.Bgm.gameObject:SetActiveEx(false)
    end
end
--endregion

--region Anim
function XTheatre3BgmControl:_PlayQuantumBgmOnAnim()
    if not self._QuantumBgmNode then
        return
    end
    if self._QuantumObjTable.Bgm then
        self._QuantumObjTable.Bgm.gameObject:SetActiveEx(true)
    end
    if self._QuantumObjTable.AnimBgmOn then
        XTool.PlayTimeLineAnim(self._QuantumObjTable.AnimBgmOn)
    end
end

function XTheatre3BgmControl:_PlayQuantumBgmOffAnim()
    if not self._QuantumBgmNode then
        return
    end
    if self._QuantumObjTable.AnimBgmOff then
        XTool.PlayTimeLineAnim(self._QuantumObjTable.AnimBgmOff)
    end
end
--endregion

--region Event
function XTheatre3BgmControl:AddEventListener()
    XEventManager.AddEventListener(XEventId.EVENT_THEATRE3_CHAPTER_CHANGE, self.PlayQuantumBgmByChangeChapter, self)
end

function XTheatre3BgmControl:RemoveEventListener()
    XEventManager.RemoveEventListener(XEventId.EVENT_THEATRE3_CHAPTER_CHANGE, self.PlayQuantumBgmByChangeChapter, self)
end
--endregion

return XTheatre3BgmControl