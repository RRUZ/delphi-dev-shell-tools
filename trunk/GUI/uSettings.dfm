object FrmSettings: TFrmSettings
  Left = 0
  Top = 0
  ActiveControl = ButtonCancel
  BorderIcons = [biSystemMenu]
  BorderStyle = bsSingle
  Caption = 'Delphi Dev. Shell Tools Settings'
  ClientHeight = 572
  ClientWidth = 548
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnClose = FormClose
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 13
  object Panel2: TPanel
    Left = 0
    Top = 537
    Width = 548
    Height = 35
    Align = alBottom
    TabOrder = 1
    object ButtonApply: TButton
      Left = 6
      Top = 6
      Width = 75
      Height = 25
      Caption = 'Apply'
      TabOrder = 0
      OnClick = ButtonApplyClick
    end
    object ButtonCancel: TButton
      Left = 87
      Top = 6
      Width = 75
      Height = 25
      Caption = 'Cancel'
      TabOrder = 1
      OnClick = ButtonCancelClick
    end
  end
  object Panel1: TPanel
    Left = 0
    Top = 0
    Width = 548
    Height = 537
    Align = alClient
    BevelOuter = bvNone
    BorderWidth = 5
    TabOrder = 0
    object PageControl1: TPageControl
      Left = 5
      Top = 5
      Width = 538
      Height = 527
      ActivePage = TabSheet2
      Align = alClient
      TabOrder = 0
      object TabSheet2: TTabSheet
        Caption = 'General'
        ImageIndex = 1
        object Label1: TLabel
          Left = 51
          Top = 17
          Width = 40
          Height = 13
          Caption = 'Updates'
        end
        object Label2: TLabel
          Left = 3
          Top = 72
          Width = 126
          Height = 13
          Caption = 'Common Tasks extensions'
        end
        object Label3: TLabel
          Left = 3
          Top = 120
          Width = 136
          Height = 13
          Caption = 'Open with Delphi extensions'
        end
        object Label4: TLabel
          Left = 3
          Top = 176
          Width = 144
          Height = 13
          Caption = 'Open with Lazarus extensions'
        end
        object Label6: TLabel
          Left = 3
          Top = 230
          Width = 151
          Height = 13
          Caption = 'Calculate CheckSum extensions'
        end
        object Image4: TImage
          Left = 3
          Top = 21
          Width = 32
          Height = 32
          AutoSize = True
          Picture.Data = {
            0954506E67496D61676589504E470D0A1A0A0000000D49484452000000200000
            00200806000000737A7AF40000001974455874536F6674776172650041646F62
            6520496D616765526561647971C9653C000008C14944415478DAB597095454E7
            15C7FFB321AB2CC23028B827B2680D8B4B35E2119B460B04266E24B58A4D4CE3
            69AC2022CAA6C82252638EDA4413AD9EB45A342898D6137B342A4B4A15881114
            10181641188655860166657ADFE38D5202687A4EDF39F70033F7FBFEBF7BBF7B
            EFF7E0E1259F8D9BC36D5D242E19E6E6E69B241289B9EB94C9B0B2B282402080
            ACB6168F1E55E57FFCC7432BC97570FF81D4283E9F1F613018263B393941A150
            80C7A32F0C86EC01B57A2FF9D5909F91D997F712DA82BD7109274422D1566968
            08E6CF9B0B1E9F8FE69616DCB973977ECA515D5D9DFBE9F1A3E1E4DB959276A8
            7AB2C445B27CC53238393AC2683492380F1A8D063535B5B879EB369A9B9BDC4F
            7EF6693503F1220041CCDEB8AC057E7EA41DCC0AF7ABFA702B370FF90505A828
            2F4F57A97A9B0AF2F30AC9B72D3935FD7BF7397324FEFEAFA3B4EC215A5B5B41
            99604DEC2CC63C2F4F0251E3D4E933484EDA674E6B34E30108F6C4C667F9FAF9
            48D74AA5E8ECEC425777376E9378555555C791C319EBC8A79D4C49A68A8ADEB3
            C1CBC3F34460D02A022C8041AF678F47A95432116390126E1C1C64932E10F071
            607FA203FDD13D160093F62C5F1F5FE99AB743F0B8F109FAFAFB9097970F994C
            D64CE2EBC9A79149399996CC2C2939AD6EE3C6779C6B6B1BD0D6D646510B2014
            0AD0D0D080DDBB2257938F6ED8FEDD64F56301907822A5DD572A0D7D0B0D8F1B
            D928CCCCCC50F6E0016E7E7BF3EA179F9FD8467E8A619BDA53E1754545EE40CE
            D7FF6023678C59535B2B437454A43B276A7A98757D0CFC4800617C6252B6AF8F
            773073E675F50D24AE8256AB81502484CF6BF371393B0777EE165D3D9C912E25
            7F3DB74EBC2F2945F1C1D6F770F3761E84244E450B0B0B735456563200CE4C8D
            8C96EA91003609FB929507F6C793783D1BB946A38356A3C500158FF98409F05F
            B614541B3874307522F9F79A0012F7272B7EBFED435CFFF6261BB9B939631628
            2B7B4000112F05C014DDC5C58B16AD59B0C08F2A58018D564BE21AF627D3466A
            B506F6F676B871E30632D2D3C45C11B20071F109F78383825C7A28634CBDB010
            94817B25F7B03B7AE7B800C294B4F42B4E4EE2C06953DD307BD64CF6DCADADAD
            296A0D0BA0566BD963A0C182BABA7A388B1DD1D2DC9C939010C77482816C5244
            64544E5858D8327B7B7BD4C8645480423663AD34848A8B8BD9566405692630BF
            A7A7A54C30D5804DEAC10C65EC9E68D6E1169D615D5D1D3BB9A64D9F41E26AF6
            080669A0D4534D08857CFC367C339E76B5E3CA85CC4B11B1091B9363F79E7B23
            3078ED1C4F0FDCA7FE57A954B0B1B16121D84C10084D50AA0B01E42DADB89C93
            5347D3D097E49E320093F6C4C65DF6F1F659EEE1E181DE5E25CACB2BD94D44B4
            B8BD5DC1268A9968B61327C2DBDB1B46BD169E73BD109425437D67AF61FB2B10
            C4872C455169397A689D8A8695BD9D1D654ACCAE63A2D1E974A87CF4882DCA7F
            5EFB467AEFFB925C13800DD98CA8E898E3EE733CFC67BD32133A3A7399AC0E55
            8F2A6F1515DDB924128A787A9DD63863AADBBAD0909015768ECED8F9830E9181
            2B512457A1B8518EA93A3976CE1E44A3A20305FF2A6CB6B5B57520690B2B4B4B
            0A6AA85695CA9EC2539F9F8CA15F1F736DCC1E8190CC8E6C2A417C326BD66C7F
            57575794969622216ECF62FABC83EB5B1199C3FAB56B93AA166E5DFDD1AAE578
            D83E8056951A3A231F25B5F50812C830F830B7EDE4E9D3EF72B5C1A78BCB9A46
            721FD7B23D9CB069803DBB0B04CC30612076EDDE7B9C0A6949AFF26961FAC1B4
            30AE7A99CD0416019B3CA604BEFF43EC9B0B715F310079EF00F43463F5B44DBF
            9E87F28A12B426052F25DF2764030C0057E8466E0F0DF7B97E78176004C464B2
            89DCE46AE47A9DE7B0ED4FB3667AF9D4A406FF1CDFC8BAD1D2AB66C575B4AD8E
            009AE99EB034F4604DC78DAF6312F731E0EA611A468CF1FC6812925990997129
            62680D0EBF3B3663E65CDFDA94E025ACB85CC5440E565CCF89EB3BEA90FFBE1F
            D47D2A6467665EDA119718C6453DEEF3A2EB983F29E6C2A685EEAF9EFDC30A6F
            5C1B216E20F1D69EA7D0773DC6511F1104BC412CF27D0D5BFE5E8DE28E41F428
            9557DA9382D60D4FF94F01E03B449FDF1CE03DFF4CC40A2F5C7CD8C5169CDEF8
            5CBC5DD98D06851C01A55F5C5F1FFAD62F274B243850A6016F921B9256CF43C6
            F50AE45654E774A4484D03EBA501F8F6BBCE6F22F1B31101CFC50DC3C43B945D
            686E7D828E2F13C2B435C5F2F07736EC972FFACD0A91780676ADF4C4ADDA5EFC
            62BA0D8EE69623AFA2664C88D10084F671395F7DE0EF270D9CE78AAFCA3B495C
            F323F196D626745F4CDFD0FF20AF842B3897578FFDBBE45CF8621CC96D431FCD
            92E9769658EFE580A3B7CB2913A3438C0410D8C7666745BEB954EA3F5B8CAC8A
            4E28C612CF4C5DD75FFE5D3186FA9A39638963F4F9F356CE33FD5D9CDC6033C1
            086B110F6E761658E7393604EFBF221F120F65C5297245DFE8E29A8AC2D48EBF
            25FF99D6C831D4DB4C9BB113551275F6B8F514777F6782B0A25EB2A2BE1A0FE2
            D920728ACB3EFDDEF285E1ABBCA68C224E4341D58BA6967A68CABF4BEBC84CFD
            12CF878DA9C79F4D5497A8B39F301062314188C687300158BBA55DEFCDDCF206
            321F0C1737B291ABE83DE0F1931AF497E5A5765C48FB2BF9B760E8956A70E411
            829BA86341AC278863B915C8AB945D551C08919A001C034E15B57F14B000E74A
            5BD8375866CA99C41B485CDFD59A2F3FBCF9432EF2D1C45F0C4135319D20DEFD
            993D023FBB86B6C45F4D3401883D8FE42AD2D62CC799E221002603CFC43BE5F9
            F28FC37760E816EB19477C4C086706C28C073B73019AA87D6B6555798A8C5FBF
            6D027012C76517C584BE3EFDAE9CA2D618D0D3C79C791D745DF202F9E1F0080C
            DD0B4F31CE541B17C2D5C3DFC5791ABA3A1BD15E5F91AF38B2653B7D576F02B0
            259B2D89BB9CCD33B79CCAE70DBD3A19DA9AAEC98F6E8DE7C4BBF112B37D4C88
            5D7F396EE6E4BA44DBFEA4507E78D37653402600E6AE9F443605433721738DEA
            3851F94F8C7C2C08D32DCBFC27D5620A68F81C60202C317413F2B8736626DCC0
            FF10F9C8C774CB8AB8C09EBD13BCCC7FC7FFD7E73FD9C3679137732246000000
            0049454E44AE426082}
        end
        object RadioButtonCheckUpdates: TRadioButton
          Left = 51
          Top = 36
          Width = 166
          Height = 17
          Caption = 'Check for updates once a day'
          Checked = True
          TabOrder = 0
          TabStop = True
        end
        object RadioButtonNoCheckUpdates: TRadioButton
          Left = 240
          Top = 36
          Width = 137
          Height = 17
          Caption = 'Never check for updates'
          TabOrder = 1
        end
        object EditCommonTaskExt: TEdit
          Left = 3
          Top = 91
          Width = 518
          Height = 21
          TabOrder = 2
        end
        object EditOpenDelphiExt: TEdit
          Left = 3
          Top = 139
          Width = 518
          Height = 21
          TabOrder = 3
        end
        object EditOpenLazarusExt: TEdit
          Left = 3
          Top = 195
          Width = 518
          Height = 21
          TabOrder = 4
        end
        object EditCheckSumExt: TEdit
          Left = 3
          Top = 249
          Width = 518
          Height = 21
          TabOrder = 5
        end
      end
      object TabSheet1: TTabSheet
        Caption = 'Menu'
        ExplicitLeft = 0
        ExplicitTop = 0
        ExplicitWidth = 0
        ExplicitHeight = 0
        object Image1: TImage
          Left = 8
          Top = 21
          Width = 32
          Height = 32
          AutoSize = True
          Picture.Data = {
            0954506E67496D61676589504E470D0A1A0A0000000D49484452000000200000
            00200806000000737A7AF40000001974455874536F6674776172650041646F62
            6520496D616765526561647971C9653C000007AA4944415478DAB5576B5054E7
            197ECE9E3D7B4320320882C825DCD1B45570A185B690FC68C5D6984E34494DA5
            6823353636D31F99281605C57492696DD40463D4D609229A1A1D0BD8641A1523
            7209974151100115130592C628BA17963DA7EFF7ED01767141274DBF996FCF39
            EFFB5D9EF3BCCFFB7E670500DA194555479D826681AC2898B02993992799C79B
            008D20400BB9F2F382EC4564181EF300BEC145FFBA53BCD00C85006884B19547
            161FC1A5B86FAAB83D2BE360A83E77589228A2A0A201FD053FF5A3C7417700D3
            A615560D942CC9C0D37BCE037A0D4083355A013A42A3D38A90D855645DE3BABA
            DBF93851BDBAC648E3E64A643387EAF1FB0FCEE2CB0DD941B4E717EE00820236
            56F5972FCBC4D2C3976050273126448D4A1DDDB3AB3862A77B0DDD882376F62C
            AA76F64C8B32BF963ADB40205BEE9C402C2B3D8DAF0AB383C934E001C0BFA0B2
            FFD88A2770FCF2D7304982CB3A8E766FB42AF03428E37F559F6558C1CFE3A662
            D1DE8F71BB68C1FD004CEB2BFBEF6DCAC6FFBBF9FCB10A96CD5E0018F32BFB2D
            9BB3B1E7C336A259C329736F4C634EFAF9C10C85AE632A55D874514B5D623CF3
            81829304EE74895C2368A1A180C8CA10926627C0B8BE0AB6E24900947EDC0149
            1279ACDD9B2C030E59415A98408B09AE50282E008A64C094F4300CB6DE83EF77
            7D60ADED83E87082455FD4E8F0C2C140BCFD8BAB88898F78308043D59D68EBE9
            E72C780250302B2604A933459C3C7902A1A1616035233A2E9E03507CA6C29462
            80B5C90EC962C36F4BFDB1EF9756E49619B1EB99FF60C83188E8D88700F0FEE9
            CB94422257323CEA81822112525AB8763404A30CE80C90CCC170B40F439748FE
            4F6F41276BB1BCD4177F5F7A87E6DD83D36945544CD483011CFEA40B5AAD370D
            281402A800305698D8386200069F310DD8AD1087658ABCA8CE9509800DE19161
            04A09200FC6C6200476BBA0980C873783C00CE40A4EE7E0DE88CC0F702801EB2
            3E4A713F37C835C082286AF47876B711EFE50C20246CDA83011CABEB465BD780
            171192066243F0FD4803FE59518188C8486E4B9AFD1864C680EF2390E368F34E
            055ACB107EB5538FC32B152CDE25A06C85856B206446D0830154D6F54CC88083
            18304719BD32E048F283F4198D9929C0D86E835E16B164A78443790E62EE2E0F
            4148E8F4C9005410800538DE70858E01EF1AA0B0C21C69F4AE01E314BE148326
            D898069C5496C5D16A213BED080C0A80814468F72E4217800F3FBDCAB3409880
            81D4681FCE009BC66C3203A237E26EAC09BE7D0AEE4E17E0DFEDE00034028583
            0AD4C21D5A1C5D6585C98FB265FD710C17674F0CE0DFCDBD68EDBC492C0870CF
            4327BDFD77E24803D17E3870F020A2A3633980397393791A0A3E7A0C12FD01D7
            154854049FFC8B80D5F11FA1EDE279F62580C484582C7A6A0184FC8F802D3F99
            18C089965EDA7C922C88F15319C01803A481DB513A04F72BF820E7090CFE3017
            BF59F63C5E7BFD75AC59B38A8FDDFAD76DD858908F97B76C43886039F2EABAB5
            8BC9EC1C05602000560250DD729D8E559706DCEA904B03147C73AC3F6763A438
            319FA09548064654545452AC9DF09FE283BADA5A44473D8AB92973F91A4D8D4D
            E8E9E946467A3AACA4910B17DBABD6BDFACA93E41AF600F0C9B9EB3C0BBC0170
            900ACD71012EE52B230CC85C7A924E8F929DEF222A320229C973A0D0E161309A
            D0D8D4C4E7CF4B4E86CD6AE12FD77AEE3C5A5A5A6FE5AF7D25825C831E006ADB
            3E47E3A59BAE108C64824AF55CAA03A98981D8B37B2F12931229B564A4A6A571
            B07ABD1E368B1545C57F4246463A828383D0D1DE81ABD7AE524825CC0C9B8184
            C4040C0C7C81FAFA7A6C2A2C48A695BBA8DFF1005077E1069DAE9A0919488B0F
            84ECC600EB9224A1FCD03FE86D9B9110178779F352D076A11D973A2F2167E973
            7C8D7DFB0F209E0EAEC76625A2A9B985805D637B541290451E00EA2FDEA0B7F7
            3C09479A83DE382D611ABDB9320A8A8D65005E7AF90FC85FBB96AAA38CCEAE2E
            D49C398B258B9F426C4C0C9F7BB9AB1BFBCBCA91959589B8D8583EE7CD6DDBB0
            B968A39F0780C68E9B9C7A6F85886D9C9A1044629447BFC2180096352FFE6E0D
            F256AEC4D0D01075074ED091FDEC338B3D001C3CF43EB232B3285C124CA48FD2
            B232BC56BC29C8A3143777F4B9008C7B7B453D0F5212A7AB65508520B8EA45F9
            81729C395B8FF088703CFE78167A7B7B71A6A6062FE6BDC0FD25EFEC423A6540
            787838AAAB4FA3AFAF1F76BBF5F4F637B73ECD01F81554F5DF2E9C8FFFA50DDC
            F80C1BB7BC81DC5FE7708AAF509CCFB5B6C26E1B8239751E222322303C3C8CF7
            4AF7A3A1BE6E4D5D6DCD499A768DFF2F98BEE158B345D186399C23D93D415370
            BF97587092D29FBB538DF9E6D9484E31C34229A7A7D49459D1105CA1B20FD9E1
            63F441534B131A1A1ABEDAFAE737E269F6D70C803FF548EA012CACDF90006D5E
            CEB275E68C1FFFC8E4E78753A74E61565212E6CF77B17AE4C81174F7F4203333
            13F70607D1D8DC7C6AE7DB3BD85FB4DB0C007DD2C2445D07DC17FE876D7AEAC1
            CB97AFD8AE379A924ADEDAFE7CDEAAD5C78A0A0BB9B360C306BC53F2D6C255AB
            5F2AB5DBED17F7EEDE9547E62B500BD1B7D1D8D93B957A286383BA332777F90E
            83C198C19C369BB566DFDFF6AE56C7B16F764A37DC825A8ABFADC63636AA2CB2
            FB10EA81AAEF4B7553B639939155BDFFC6943F2C1883FA6C73DFD4BDFD17E30D
            AB9A701A1D8D0000000049454E44AE426082}
        end
        object Image2: TImage
          Left = 6
          Top = 294
          Width = 32
          Height = 32
          AutoSize = True
          Picture.Data = {
            0954506E67496D61676589504E470D0A1A0A0000000D49484452000000200000
            00200806000000737A7AF40000083C4944415478DAAD570950545716BD7FE985
            5D1609282E611182CAD64AC380420021602010E232E2A82CC61A2B8963E218C7
            68446BC6A1468D599CA809182501A7001D70C4A5630302824A18650D01224B83
            B2354BCBD2CBFFFDE7F56F6D6C1625D6DCAA2EFE7BFFBE7BCF3BF7DCF71F18BC
            A4CD758FE3A03FB6E82747BFDECEAA0CE665E260BF21A11D4EF236633867B595
            A5B995CD6C7323EBD9963CA54AA5EEEA962A1E754B652323236D6A5A718E5153
            9711A091FF0B0094D89EE0189EF4745FECF5BA9FC0D24FE080CDB1369EE44733
            0CD437F542E94F0D94A8A0EC5157574F0E4D8DED4340465F0A004A8CE324FF84
            B39363CC96F5E13682C573674CAB5245C3E5C23A7566CEE516D9D0E04792FF7E
            97F79B00A0E46604C9BF141B13295C1BB18C87E333CEAD6743C30A387E3AB7BF
            B6BEFE84A432EDC08C00A0E47C0ECFE856E2A6759E3E9EAF3EB744B939E780CB
            E54144D4FA697D284A0D3F5C2C919794DE4A6DAF4C7DFF8500E62F4BCA7FE7ED
            B7C2FD048E7AEFB233BE863571DBF57C0B4417E19FC73E81FD8753C143E0372D
            0846CD40DAF9EBC3B57535EF4B2ACF9C9D16C07C41D227CB853EFB234396F326
            064978C71352B32A0009831DB73D688094FD0930261F05022720E1BD64F00B88
            9C16845C41C1B76773FABABADA8548980F260140D49B9A985955276D5EB780CB
            25F516773F6A85BFED5E8BE8E6838999051CF82C17EAAB6EC1E9631F02C368DB
            1F4742D9BAF3182CF6D067422E1F013EDF887D6EED90C2C58B178A5B2B520326
            0140D49F5C1910BC6DB1F3BC4965292FBC0097CE1FD72EC03088D9F86710F8BD
            0907DE0B463556E9FC787C4348FE52A4B7F68B839B60C78174DD38FF5AA1A2B5
            A5C9B7E35EFA3D3D004EFE1F34C646BFE58413937597FEE507D0D152AB1B7379
            06B02B251F8EEE590D4AC5986E9E2039F0F191EBBA716F771B7C9B120F1BB61F
            85854E5E5A367B86A050FC9FE20777CF04E80020FA05F64E6EA55E5EEEFCA9EA
            F7CD5FD7C2D8A86C5C388805EFA038A82ABF04F267E6F986A6B06D5F16FBDC58
            5504D7B2FE814AA40623530B48DA93C9CED33403A2AB79438D65A766E90020FA
            4FBB0B56BE6B6D356B4A01DDBC741C9A6B0AF5E68C4CAD40B82A096EE67D8646
            0CA2DF04D6FCF114905CED1ED28FAC039572EC893E0888DBF93D70F9DA13B4AE
            AE8AEE93DC0F6AAEBC50CC0258B83CB1C2D33B6C199F4F4E0980528E42DE37DB
            5040EDA98AA14E0888D90B360BDCA7F4EF6AAF86A29C43ECEE9FDA22CF081004
            25B1CF0F3B3B41DA5A74ACF6F6855D2C007BEFAD8D1E3EA14E24A13DF2A45D4D
            6069E33429B0A4B10C25C7C16A8E2B4BF774762B2F053A1F54E8CD39BABF015E
            415BD9E77E691F3C6C2C12D7DF3E1FA205207C57E2E51F6647605A00B95F6F41
            87871A684A0E16B68B2030F653C0492ECCD4F24E26807C64605C330874F0FAC3
            6039C7991D0F0ECAA0AD5654DB703B63290BC0419828F1F07FD38EE410AC4341
            E65EE86D1F57BD46DDC2D57F8279AFADD067A4A10C7EB99B0B3269BB5684C616
            10BAF928DB9AE2EF77C3D86329A0631D9C8531E0E21DAD5BD7DBDD073D0DD76A
            6ACBB3DCB400BCE39BDD02A21D0C8DF9BAC0C5FF3A84B4357EC7C0103B731679
            43E08683EC5894F621F4497ED6ABB3C6B8062610BB2BF3B98C497E6D81C7CDD7
            0AEF95E506B1001C859B8A9D7D235758DBBDA2734ADF13824AA0D45B487278F0
            87BFFF081DBFDC811BA9BB75A7E044D380F08EDC0E4ECBC2352D30E12DBA37DC
            BE4D33DDC5E9774BF21358004B7DA2779AD8071E71F5F725D05659B7FAA26C28
            CF3AF6CC0E31B07E750944ED4E833B399F438D38F3F94240710882048FF004F0
            8C48D44D534A15DCFDF779850DF1F3C70562F1176C365FBF004B19D7AD4310BB
            91CF331A3F8BDAEEDF8492EF92918808B05BF23B08483CC4CEE7EC8B8581CEE6
            19099283BE035B4E963DD93C037DEDDDD0703D63C8D6A023B4A0A0E0AEEEDC75
            F1DDD8B860C51A273B3747C4DAF4D7809A2B67E14EE651B64B6604C0000148D3
            B624A550419D4844639D45D5D44897B0B2B252A5CBE41F181137C85D726669EC
            7AAE81A5E9945725E5F01064240A414D53334AAE29DB6CC7A510957211D408B0
            B4B1039AAE673C9EC36D4D118BC587B51E4F2C393919BF70A3B16E967BB8F37C
            3F6F8C636CF0540E7A762EC601D4CF7C01A74D4D1060B1F03588FAFC0A4ACEC0
            48F700FC9A9F47190E9657733079585151519F1E008D858484AE78A85A70C566
            E5DBC6B3DD5C80D480981058BC772D3CBA5FA2D7A26C20841643A2E399988343
            D806708DDD0E5C635356C48AFEC7201117D2CAE6822E4B5EFFA7376EDC3833CE
            D1045BF97AE8EE5ECCF9A04D6034DFCCD5013866C6EC658379C6F3DE577BA04D
            9CADE9288DB2C0D0DA0E5C7EBF03E607C53E119B36B05AA50279EF20F4DEA960
            1E57FF3868CBEDCCF0F7F7DF81D8564F0B4033B72230EC2B29E9146FEA196C60
            EEE98691B34C8040DDC1686AA2D9E934B4EBCE058A067A6414945DFDD05B5244
            D3929FFA67E3929B344DC723EA87F5553285050606921887B7A7879EF71161EB
            6A62EAE643F01CE6016E844AC2E302C6415F4DF4E1D2D0AED92DDB11B41A18B4
            63B55C09F4800CC6EA9B40565FA63294353E32C3FBAE2A148ABF9496960E4CCC
            F5DC6BF7AA55ABA286297EF220C7DE997CC591C75BE842706C6D00373701FC29
            10B46B06B517235700D537084A493BC85B6B55F850FBB025D3D6426274BA8585
            C589ECEC6C7A4AB1BE48CDE1E1E1A60A8A8A5750BC7819693B57C5B534C27846
            88213E86F30D3106B524A31C53AB55720693CB5406AA9E0113754F1F4A7C1531
            740A09AEFD79F167FCCF292A8B318671FC308259891679500C6943A9493E8EA9
            1902A3E424CE4891061AD0BB6224DA129148D43393B833063085E1C1C1C1E604
            32333333E97414BFC8FE078F57464E0AB343890000000049454E44AE426082}
        end
        object Image3: TImage
          Left = 8
          Top = 99
          Width = 32
          Height = 32
          AutoSize = True
          Picture.Data = {
            0954506E67496D61676589504E470D0A1A0A0000000D49484452000000200000
            00200806000000737A7AF40000090A4944415478DAAD570D7414D515FEDECECC
            EEEC6E76373F9B4D90840450420820290462428F55A0B4225439D8F277A8687B
            2CE7B448A18A8A20AD42058196DADAD64341FE8E1A41E08884F25322151048C2
            AF1542480324D924BB9B6493FDC9FECC4CEFCC6E42720481B6F79C979DF7E6CE
            BDDFBDEFDEEFBD30DC83B8ADE9F912C3B76460800285C90A584891AF8580DA21
            1DAEFDF762AB4BD81D9D26A6E73383B88833E827739919569695059DD904D812
            A178DBC02409D1AB3590BD1D7E7F67F0B0B3BD7DD3A8869ADDFF3380A6C4F4FE
            7AA3B845976A1F2B8C1F0F6ECC2830AB15B2BF03525482D4D202CE64049F940C
            6634021DB4FED565C8A72AD0D1D078FE5CA7FFE589172BF7FD5700DC297D9FE5
            6DD67586E94F59F9C98F010A20373421E4AC4324C906F3D8B1101C0E780F1F86
            5CF64F1824059CA0872EB32F584A32E42B57113D711235D7AFFFFE1913B7A2A2
            A2C27DD7003CF68C67857E991B0C0BE783CBCD815C7B0D91E66684051EDCF061
            B01414F4D20FD6D4C0B7670FF83A27F48A0E3A42CB4C66283C0FE54A151ABFAA
            3A5C58573DDBE57235DE11801AB93864C806FDE245D0259810BE701191480472
            FF2C248C7B04BCC57ADB54B61D3A04E9F817D00742E0A351308E8774B90AD2F9
            0BF85730B0657C877BB1DFEF6FBC2D00B5C285AC7E95C6DFFE068C9C878E1D47
            A7498479F2248803EFBFAB828AB6B5C2BB6B3784FA467037EA207D7A008ADF4F
            C124E0D35060C90C57FDCADB0268CBCEBD68FCC5BC3CDDE891081F3E82705A2A
            8C3E3FA03700947EC67350142A062A4050A2359125EA822814AA019A50AD289A
            AE7CBD1ED1BDA5909B9A637A3A86A8680CCEF4367FEF80BFE3E8D700B89329F5
            C50F6D302C5E08A9E20CA24E27A4E179B0CE987E57917FAD88376E4474D12B30
            A91521CB3147A2880A8E953CEAAC7D91A6D77A01F00E1872C3B0F0F90C5D7616
            A2FF38028806842D66889C1E4C4FC52408603440FB4A16E92B9D16BD668017A0
            70E4C8E783547E06D2D1CFA1504BAAD95054DD5024EE89B2603607ED0D571FA5
            D917DD00DC96B47C43DEE04AF18DE5904E96436E6DD1D046F5021296BEDC2BB2
            70430374160B15A3A57BADB3AA0AE2A041BDF46E24A7C34A1DA16D497CA89BC4
            8837DE6B6B59B920D4F1679AD669005C96B4D7CDB3A6BFCA4F9D4C45B31F0A45
            4FCC07C5A04750CFC1F2E33910525335C39E9D3BC1DBEDB03DFCB036F75594A3
            EEB5E5C85ABD1AC6DC5C6DAD7AF62C58F71D81419D68BEE32054671C87D3A1E0
            FE09C1B617687A515BF3E48D3C607E7ACE0410BDCAD5D5143D7D2A1A89DD0C08
            51E119A64D8521234333E05AF926909284D4E79ED3E6CE3FFD11ED6FAD439FED
            5B612D2A821AE7D5C7A720F1780578D567DC7157161871435D247C79A8DFF30C
            AD1E8F01185178DA34E5FBA354F6525C1EAA7ABDA6A812899F45615EBE0CE6A1
            43353B3545C5E07372D06FD3466D5EBF6E2D7C6B7E873E251FC0525CA439B93A
            69326C272A21F4041007C11CA9E86C7605D37DAE2768E58C1A137325F73D667A
            EA89A2E827A554918C0A8AA362D3519D71F02202EBF6CDB016166A36AAB20740
            3F6634B23FFC403358BFE62D745006EEDB5942008A63001E57019CE905408903
            E0063D00A9EA0A9263004EA94964CD897D3E378E1856ACCB1081A47871714CAB
            DA568F1796054B61CD1FA52D5F993601FA418391B5E20FB10C6CFA0B02BBB6C1
            B16C2DAC230B3427B58B7E065B2BD13265B23B038C7E231222D765C8A7CB61F7
            B9A6D1EA49B5103500A2C3512CFCB000CC2CC69415CA050168696C8679EE0BB0
            0C1FA9D9B93A771284FE83D16FE91A6DBF9DDBDF45B07407ECBF5A016B5CA776
            D97CD8A536E22F83C64DF14A248212E039DD02FF91A32D83029E9FC601D4B37A
            5BDAFB0926F374FE4785E0ECD63833684D8356A71BA69F2C86F5C1519A91EA39
            13210CA00C2C5F1F03B099327070275217AD88E910E9D4BEF63CECD1B6580628
            1825C64390EC19706E2B83FB7255F5437ECF425A2AD7B6A0DAEA58929A90F006
            FB760EF443336FD68C24A3C5E942C2BC25643C96DEEA99E3C00FCC45D6EB6F6B
            F30602E02FFD10698B577567E0FAF2F9480CB44030E9B5203406A06C4A838B71
            63FEAF511E0CEE7FBAD3BB965E9E554993FD3DD1915768B65C94D2CC304D191D
            432B4711686D4787251DC6FC4298EECF81444CD7B4632B383A581C53676900BC
            C7CA10A8BE045BD17760261DD559DD96BFC2C653F750010BD4D26A02B8EC1C78
            6B5AD1BEA104CBDA3D6F7C14E9DC1BDF8258C29D8E7EA70C3A56C04FCE87705F
            32C2A110227945489935EF6646A0F4EEEB2E89737DCFF7FE2FCFC0FFB73761B4
            2410FB59C08D1E8F1ACAA41C0CB58D68BCF67352A9A071A91BC0519BE3C9E126
            F3C7527A024C93F2E1EFF0C1E56E8792D2B7DB0F23E3723CA99A5F25F62CF778
            DF0DB6330073D4071BDD908CC513E12E2D8377F32E948AC2472F36D5BF17E700
            673700ADA55233CB45B09172517FC8630AE07869752CAA1E4CF64D51F7241C55
            DC7BDE8728D001E469A7D65C8188516C1CE76B79952E25AAF3CAEEC0BA1EDE11
            AD23A7D9923E9314D91C1D3704C2634F22120EDD6CA59ECCCAE20FB2720BDF0A
            0C297688893648F575B8B164150C21192B95F0DA6D1ED7415238DF157D2F00AA
            94D8ECB327982C5B7D7208AC783004DA922E42537A442AF77C66E86E3546AD67
            C8CDA7D3310FC1B395A85FBF05067F187B79B6E32597B384542E74EDFD2D01A8
            7228297DD930D1B898A237718FE4C3347A30583800A9A3AD6B4334874A7C83D4
            BF3A9B1D5CDF6C08990349CF0BCFEE7D68FBE4333A1179ECE5D88E575A1A7749
            9274A967EA6F0B40955536FB8C9966EB7A2E1249ED343088E30B601A31045C4A
            0A9D9646C88180E6985993E87E60A3EAF623DCE884EF54255A0F9E006B0980D3
            EB3BDFD5C99BDFF1349791F3AA5B39BF2D00552689A631BFB4D917E4EAF81F48
            E1B031C229C46609D0A598692481B7D910A13B63B4C98568AB0F118F0FBA4014
            7A518F738C9D5811F27D7CBEADF53299FA37E267FF3D01884BE677531D79F344
            EBCC0151A930C9EF7F204A0C2951F412EB226CBA73524DB4EAF58D67CD62C506
            295C76CEE3BE160E87EBE955038DDA6F7270C7FF0DE3924D23451D7305D38389
            8CD9A80C74B27A6A91BC1D0E7C493FD432A0CB20E85201773CF23BCADD02E812
            F56E26C607DFE37BF5861AA4D149A3F95E0CDE2B80FFBBFC07D719EC4EBC2AD6
            C90000000049454E44AE426082}
        end
        object CheckBoxActivateLazarus: TCheckBox
          Left = 44
          Top = 294
          Width = 363
          Height = 17
          Caption = 'Activate Lazarus support (Only works if lazarus is installed) '
          TabOrder = 11
        end
        object CheckBoxShowInfoDProj: TCheckBox
          Left = 46
          Top = 44
          Width = 209
          Height = 17
          Caption = 'Show Info Panel for Delphi projects files'
          TabOrder = 1
        end
        object CheckBoxSubMenuCommonTasks: TCheckBox
          Left = 46
          Top = 21
          Width = 361
          Height = 17
          Caption = 'Create submenu for "Common Tasks"'
          TabOrder = 0
        end
        object CheckBoxSubMenuCompileRC: TCheckBox
          Left = 45
          Top = 67
          Width = 236
          Height = 17
          Caption = 'Create submenu for "Compile Resource files"'
          TabOrder = 2
        end
        object CheckBoxSubMenuFMXStyles: TCheckBox
          Left = 45
          Top = 260
          Width = 347
          Height = 17
          Caption = 'Create submenu for "View FMX Style"'
          TabOrder = 10
        end
        object CheckBoxSubMenuFormat: TCheckBox
          Left = 46
          Top = 214
          Width = 347
          Height = 17
          Caption = 'Create submenu for "Format source code"'
          TabOrder = 8
        end
        object CheckBoxSubMenuLazarus: TCheckBox
          Left = 63
          Top = 309
          Width = 329
          Height = 17
          Caption = 'Create submenu for "Lazarus" options'
          TabOrder = 12
        end
        object CheckBoxSubMenuMSBuild: TCheckBox
          Left = 46
          Top = 122
          Width = 361
          Height = 17
          Caption = 'Create submenu for "Run MSBuild ..."'
          TabOrder = 4
        end
        object CheckBoxSubMenuMSBuildAnother: TCheckBox
          Left = 46
          Top = 145
          Width = 361
          Height = 17
          Caption = 'Create submenu for "Run MSBuild with another Delphi version"'
          TabOrder = 5
        end
        object CheckBoxSubMenuOpenCmdRAD: TCheckBox
          Left = 46
          Top = 99
          Width = 361
          Height = 17
          Caption = 'Create submenu for "Open RAD Studio Command Prompt Here"'
          TabOrder = 3
        end
        object CheckBoxSubMenuOpenDelphi: TCheckBox
          Left = 46
          Top = 191
          Width = 347
          Height = 17
          Caption = 'Create submenu for "Open with Delphi"'
          TabOrder = 7
        end
        object CheckBoxSubMenuRunTouch: TCheckBox
          Left = 45
          Top = 168
          Width = 347
          Height = 17
          Caption = 'Create submenu for "Run Touch"'
          TabOrder = 6
        end
        object CheckBoxSubMenuVCLStyles: TCheckBox
          Left = 45
          Top = 237
          Width = 347
          Height = 17
          Caption = 'Create submenu for "View VCL Style"'
          TabOrder = 9
        end
      end
      object TabSheet3: TTabSheet
        Caption = 'Custom Tools'
        ImageIndex = 2
        ExplicitLeft = 0
        ExplicitTop = 0
        ExplicitWidth = 0
        ExplicitHeight = 0
        object Label7: TLabel
          Left = 139
          Top = 34
          Width = 29
          Height = 13
          Caption = 'Group'
        end
        object Label8: TLabel
          Left = 392
          Top = 34
          Width = 27
          Height = 13
          Caption = 'Name'
        end
        object Label9: TLabel
          Left = 139
          Top = 82
          Width = 54
          Height = 13
          Caption = 'Menu Label'
        end
        object Label10: TLabel
          Left = 139
          Top = 180
          Width = 27
          Height = 13
          Caption = 'Script'
        end
        object Label11: TLabel
          Left = 139
          Top = 128
          Width = 52
          Height = 13
          Caption = 'Extensions'
        end
        object Label12: TLabel
          Left = 139
          Top = 345
          Width = 34
          Height = 13
          Caption = 'Macros'
        end
        object Label13: TLabel
          Left = 255
          Top = 34
          Width = 113
          Height = 13
          Caption = 'Minimum  Delphi Version'
        end
        object Label14: TLabel
          Left = 392
          Top = 82
          Width = 30
          Height = 13
          Caption = 'Image'
        end
        object DBNavigator1: TDBNavigator
          Left = 139
          Top = 3
          Width = 240
          Height = 25
          DataSource = DataSource1
          ParentShowHint = False
          ShowHint = True
          TabOrder = 0
        end
        object DBEditMenu: TDBEdit
          Left = 139
          Top = 101
          Width = 247
          Height = 21
          DataField = 'Men'
          DataSource = DataSource1
          TabOrder = 3
        end
        object DBEditName: TDBEdit
          Left = 392
          Top = 53
          Width = 127
          Height = 21
          DataField = 'Name'
          DataSource = DataSource1
          TabOrder = 2
        end
        object DBMemoScript: TDBMemo
          Left = 139
          Top = 199
          Width = 380
          Height = 140
          DataSource = DataSource1
          Font.Charset = ANSI_CHARSET
          Font.Color = clWindowText
          Font.Height = -13
          Font.Name = 'Consolas'
          Font.Style = []
          ParentFont = False
          ScrollBars = ssBoth
          TabOrder = 5
        end
        object DBEditExtensions: TDBEdit
          Left = 139
          Top = 147
          Width = 380
          Height = 21
          DataSource = DataSource1
          TabOrder = 4
        end
        object ListViewMacros: TListView
          Left = 139
          Top = 364
          Width = 380
          Height = 104
          Columns = <
            item
              Caption = 'Name'
              Width = 100
            end
            item
              Caption = 'Description'
              Width = 250
            end>
          ReadOnly = True
          RowSelect = True
          TabOrder = 6
          ViewStyle = vsReport
        end
        object BtnInsertMacro: TButton
          Left = 444
          Top = 474
          Width = 75
          Height = 25
          Caption = 'Insert'
          TabOrder = 7
          OnClick = BtnInsertMacroClick
        end
        object DBComboBoxGroup: TDBComboBox
          Left = 139
          Top = 55
          Width = 110
          Height = 21
          Style = csDropDownList
          DataSource = DataSource1
          Items.Strings = (
            'FPC Tools'
            'Delphi Tools'
            'External Tools')
          TabOrder = 1
          OnChange = DBComboBoxGroupChange
        end
        object DBLookupComboBoxDelphi: TDBLookupComboBox
          Left = 255
          Top = 53
          Width = 131
          Height = 21
          DataSource = DataSource1
          ListSource = DataSource2
          TabOrder = 8
        end
        object DBGrid1: TDBGrid
          Left = 3
          Top = 3
          Width = 130
          Height = 465
          DataSource = DataSource1
          Options = [dgTitles, dgColumnResize, dgColLines, dgRowLines, dgTabs, dgRowSelect, dgConfirmDelete, dgCancelOnExit, dgTitleClick, dgTitleHotTrack]
          ReadOnly = True
          TabOrder = 9
          TitleFont.Charset = DEFAULT_CHARSET
          TitleFont.Color = clWindowText
          TitleFont.Height = -11
          TitleFont.Name = 'Tahoma'
          TitleFont.Style = []
          Columns = <
            item
              Expanded = False
              FieldName = 'Name'
              Title.Caption = 'Tool'
              Width = 100
              Visible = True
            end>
        end
        object DBComboBoxImage: TDBComboBox
          Left = 392
          Top = 101
          Width = 127
          Height = 22
          Style = csOwnerDrawFixed
          DataSource = DataSource1
          TabOrder = 10
          OnDrawItem = DBComboBoxImageDrawItem
        end
      end
    end
  end
  object DataSource1: TDataSource
    DataSet = ClientDataSet1
    Left = 56
    Top = 152
  end
  object ClientDataSet1: TClientDataSet
    Aggregates = <>
    Params = <>
    Left = 40
    Top = 136
  end
  object ClientDataSet2: TClientDataSet
    Aggregates = <>
    Params = <>
    Left = 56
    Top = 392
  end
  object DataSource2: TDataSource
    DataSet = ClientDataSet2
    Left = 72
    Top = 416
  end
end
