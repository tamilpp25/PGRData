---@class XCharKuroro
local XCharKuroro = XDlcScriptManage�%�^ghw]�N��}X�;=E���:arKuror׷�G?��w���|iE&C����;��v�at�O�Vl9���� D7h�4�L�P��? = CSNԽ��Gmatics.v�q�C\��Խ1N|��*�1=ۛ StatusSyncFight.XFightScript�B�>*o��*�	��v�xarKuroro:�����q��)
   dZ.��rbw�������\(b�/

    sel�XF3�q,�hD2Sϙ�/`as�d 9   )G�CR�xnteractO��(�j�d = 0
    #�wDy�@�-�2To+���actS�N���'F}�:�)y�B�U�0xG�tingInterac��yav9��>'����� self._is]�	[o�@tate = �Dq#���   se�J�Q%n�3e�A��Vo��8듣nj��XAYZ��ɝ����._d5��b
�	���P h���Wφ4���	SR[������ؾ�    self._叻���t>��Du_        --辅助机最大移动速度
    self._nowSpeed = 0           --辅助机当前移动速度
    self._moveAcceleration = 30 --移动加速度（m/s^2Ａ\r�{�q���.��x�帧速度�Ҿr���qRwx�S����,�P  sel�9���Accelera�ש8=.�� --停止加速度（m/s^2）， 期望的每帧速度变化量：0.6m/s
end

function XCharKuroro:���
�#���tx�F��d = se\�Ѓroxy:Ge�P��NpcId() ---@type number

    self._proxy:RegisterEvent(EWorldEvent.NpcActionStateChange)
    self._proxy:RegisterEvent(EWorldEvent.NpcInteractComplete)Z���l�X5Z���DJ��n�%#ֳ�1�i�|��o����unction x�prKuroro:Upd�|!ldt)
    if k�л��t��0e��2�2����tB�˨�-+JS����
  ���cB if�b�*._isInţ;���L� then
  @��;Ө p�t�}~�N�Jw�Zi@R���v(�ѧ�M�aCo0`�e�>tion(sel�⏇4_����ߌ�nsE��u1Mcal mGg!�U��Uf�{�7[ζ�:�V[���'|alize(self._interactSpot - selfPos)
            self._deltaMove = moveDirection * self._maxSpeed * dt
            self._proxy:MoveNpc(self._uuid, self._deltaMove)
        end
        return
    end

    local selfPos = self._prox��XetNpcPositiovI
S�2E}uuid)    Г�K�cө�	�\�"ʀ��   ��ڶ%�9E_@
��vD = self._proxy:GetLocalPlayerNpcId()     --玩家
    local playeҖ�/���!����roxy:矾���v���c��@'�yerNpcU�0��S�����家��fVײ���T��	� rotationPl��_�pc = sel���M�oxy:GetN�fPtatio�`߾;����{�A�˧��5�+ple컜Q�旋���������lf._proxy:Se�x]r#otation(sel6���uid,�?�ationPla1Ԡ��������_��q+�|��X�~�.	X��� local d�&�쟋tion = playerPos + float3(1.0, 0.5, 1.0)
    local moveDirection = CSMath.normalize(destination - selfPos)
    local distance = CSMath.distance(selfPos, destination)
    local needMove = false
    if distance > 10 then �]	oe^i��f>
        local teleportGoal = playerPos + float3(1.0, 0.5, 1.0)
        self._proxy:SetNpcPosition(self._uuid, teleportGoal, true)                 --传送辅助机
    elseif distance > 1 then --1<距离<=10
      8%3�#�����[��e����m�uNf._maxS ��4�then
            self._nowSpeed = self._nowSpeed + self._moveAcceleration * dt
            self._nowSpeed = math.min(self._nowSpeed, self._maxSpeed)
        end
        needMove = true
    else -- 距离<=1
        ifX�~�iѦ%1�F̐����Y�g.0Xe��I
            self._nowSpeed = self._nowSpeed - self._stopAcceleration * dt
            self._nowSpeed = math.max(self._nowSpeed, 0)
        end
        --if distance > 0.1 then
         �l4�dMove �aVU���u�s      --en���*en�&�ڀduif needMoV��khen
   �������G����U = self._>�9	.�W * ��4H�/*\��的�;����X�P��JOz��L�^��Ns�F�math.min(spe�|�Z�Ҍ���A��x�wZ��R��_�超H�A�j�u�_���|����ކn��su�lR��
�}p{;�N��`�6�����ճ;��~f�0�鱆���z�����K���_���ă���E%�t�_�f._delt�  Lq �j��D�f��	�$�����ҥ��?�v�S�T���维移���量
     �k:L�3V�E�x�\�Z1�U�VE�9i$�/cmO�,���P�ltYֽ��b=�  Ņ���|
end�_>�6�S�2��am eventTy�w��^@er�< _��?|�Ftz�ntArgs ��$ e�p��
fun{tZ���7��ro:Hand䚡�h81I�:�ɭ��R��I���C���;�--XLog.Debug��8�(�h$������洛洛脚本，UUID:%d，HandleEvent：eventType:%d", self._uuid, eventType))
    if eventType == EWorldEvent.NpcActionStateChange then
        if eventArgs.NpcUUID == self._uuid then
            if eventArgs.NextState == ENpcAction.Move then
              ·�>�f._isInMoveS�|0 = truifu�� ��1���7(�jQ!��-���ލ��v�()�ߢ+�移动状��D	A
h��T�u��8���z>�,c]��V�2���evStatM1�b��e�A�`Jr�.Move����5��X��F���>W~A0_Q��~�!�veSta����1alse
   ��  ����4[Ϻ��w���(Zh�T!�1FC.退出移��L�#��")�o�t� �r�e�u�O��ix
       ]M�9

n�����������1���ovin��4����ZG�4�!��{I=l9d�]zW��nd�:h��+Hcc�V�^cUUID == self._uuid
            and eventArgs.PrevState == ENpcAction.Move
            and eventArgs.NextState == ENpcAction.Idle
        then
            XLog.Error("库洛洛退出移动状态，进入Idle状态，开始与目标交互")
  hF�     @�l��wc�����㋁�u�_����sR��n���
 X�����Ķ����D_��V�-cms�artInteractWith(self._uuid, self._interactTarget��E�Sl&�_�?DK*$�-ctO���+3��O9�;�W�)�4�RC�]  elseif eventType == EWorldEvent.NpcInteractComplete then
        if self._executingInteractBehavior
            and eventArgs.LauncherId == self._uuid
            and eventArgs.TargetId == self._interactTargetUUID
            and eventArgs.Op�����W����e��F-��[�-�V��#_�rAR��G$�sI�j�    hC&E�W]@���9��J��Ո1*"���
互完�\e��Z����fS�      h�'1��Z��i�?�g��606jK�7 ��6}�X1�a�seʑ/��n�z�z	�
    end
end

function XCharKuroro:Terminate()
    self._proxy = nil
end

function XCharKuroro:GoToInteractWith(targetUUID, interactOptionId)
    self._interactTargetUUID ��7�etž2�y�bT� self._inte4���tion�O�p(�N`������W
�>�.�dd��3�lf._int�-#�[q��!YGWself.#�"�xy�!�`��{`�e?ء�05�)>&�K�e����ޜ">{�>J{UID)

  �q�w._proxy:NpcMoveTo(self._uuid, float3(self._interactSpot.x, self._interactSpot.y, self._interactSpot.z), ENpcMoveType.Run)E���Q��	Q1lmovingToInteractSpot = true
    self._executingInteractBehavior = true
    XLog.Error(string.format("库洛洛开始去和目标交互：目标UUID：%d，交互选项I��m�*^�ǿ����S�<SzD��Y�w�tOptionId))
end

return XCharKuroro
