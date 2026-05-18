#Если Сервер Или ТолстыйКлиентОбычноеПриложение Или ВнешнееСоединение Тогда
	
	#Область ПрограммныйИнтерфейс
	
	// Возвращает Истина, если в задаче указан исполнитель или роль исполнителя.
	//
	Функция РеквизитыАдресацииЗаполнены() Экспорт
		
		Возврат ЗначениеЗаполнено(Исполнитель) ИЛИ НЕ РольИсполнителя.Пустая();
		
	КонецФункции
	
	#КонецОбласти
	
	#Область ОбработчикиСобытий
	
	Процедура ОбработкаПроверкиЗаполнения(Отказ, ПроверяемыеРеквизиты)
		
		ЗадачаБылаВыполнена = ОбщегоНазначения.ЗначениеРеквизитаОбъекта(Ссылка, "Выполнена");
		Если НЕ ЗадачаБылаВыполнена И Выполнена Тогда
			
			Если НЕ РеквизитыАдресацииЗаполнены() Тогда
				ОбщегоНазначенияКлиентСервер.СообщитьПользователю(
				НСтр("ru='Необходимо указать исполнителя задачи.';uk='Необхідно вказати виконавця задачі.'"),,,
				"Объект.Исполнитель", Отказ);
				Возврат;
			КонецЕсли;
			
		ИначеЕсли ЗадачаБылаВыполнена И Выполнена Тогда
			ОбщегоНазначенияКлиентСервер.СообщитьПользователю(
			НСтр("ru='Эта задача уже была выполнена ранее.';uk='Дана задача вже була виконана раніше.'"),,,, Отказ);
			Возврат;
		КонецЕсли;
		
		Если СрокИсполнения <> '00010101' И ДатаНачала > СрокИсполнения Тогда
			ОбщегоНазначенияКлиентСервер.СообщитьПользователю(
			НСтр("ru='Дата начала исполнения не должна превышать крайний срок.';uk='Дата початку виконання не повинна перевищувати крайній строк.'"),,,
			"Объект.ДатаНачала", Отказ);
			Возврат;
		КонецЕсли;
		
	КонецПроцедуры
	
	Процедура ПередЗаписью(Отказ)
		
		Если ОбменДанными.Загрузка Тогда
			Возврат;
		КонецЕсли;
		
		Если НЕ Ссылка.Пустая() Тогда
			ИсходныеРеквизиты = ОбщегоНазначения.ЗначенияРеквизитовОбъекта(Ссылка, 
			"Выполнена, ПометкаУдаления, СостояниеБизнесПроцесса");
		Иначе 
			ИсходныеРеквизиты = Новый Структура(
			"Выполнена, ПометкаУдаления, СостояниеБизнесПроцесса",
			Ложь, Ложь, Перечисления.СостоянияБизнесПроцессов.ПустаяСсылка());
		КонецЕсли;
		
		Если НЕ ИсходныеРеквизиты.Выполнена И Выполнена Тогда
			
			Если СостояниеБизнесПроцесса = Перечисления.СостоянияБизнесПроцессов.Остановлен Тогда
				ВызватьИсключение НСтр("ru='Нельзя выполнять задачи остановленных бизнес-процессов.';uk='Не можна виконувати задачі зупинених бізнес-процесів.'");
			КонецЕсли;	
			
			// Если задача выполнена, то запишем в реквизит Исполнитель того
			// пользователя, который фактически выполнил задачу. Это нам потом
			// потребуется для отчетов. Такую запись делаем только в том
			// случае, если в базе было не выполнено, а в объекте стало выполнено.
			Если НЕ ЗначениеЗаполнено(Исполнитель) Тогда
				Исполнитель = ПараметрыСеанса.ТекущийПользователь;
			КонецЕсли;
			Если ДатаИсполнения = Дата(1, 1, 1) Тогда
				ДатаИсполнения = ТекущаяДатаСеанса();
			КонецЕсли;
		КонецЕсли;
		
		
		Если НЕ ЗначениеЗаполнено(СостояниеБизнесПроцесса) Тогда
			СостояниеБизнесПроцесса = Перечисления.СостоянияБизнесПроцессов.Активен;
		КонецЕсли;
		
		ПредметСтрокой = Строка(Предмет);
		
		Если ИсходныеРеквизиты.ПометкаУдаления <> ПометкаУдаления Тогда
			БизнесПроцессыИЗадачиСервер.ПриПометкеУдаленияЗадачи(Ссылка, ПометкаУдаления);
		КонецЕсли;
		
		Если НЕ Ссылка.Пустая() И ИсходныеРеквизиты.СостояниеБизнесПроцесса <> СостояниеБизнесПроцесса Тогда
			УстановитьСостояниеПодчиненныхБизнесПроцессов(СостояниеБизнесПроцесса);
		КонецЕсли;
		
		Если Выполнена И Не ПринятаКИсполнению Тогда
			ПринятаКИсполнению = Истина;
			ДатаПринятияКИсполнению = ТекущаяДатаСеанса();
		КонецЕсли;	
		
		// СтандартныеПодсистемы.УправлениеДоступом
		УстановитьПривилегированныйРежим(Истина);
		ГруппаИсполнителейЗадач = БизнесПроцессыИЗадачиСервер.ГруппаИсполнителейЗадач(РольИсполнителя, 
		ОсновнойОбъектАдресации, ДополнительныйОбъектАдресации);
		УстановитьПривилегированныйРежим(Ложь);
		// Конец СтандартныеПодсистемы.УправлениеДоступом
		
		// Заполнение реквизита ДатаПринятияКИсполнению.
		Если ПринятаКИсполнению И ДатаПринятияКИсполнению = Дата('00010101') Тогда
			ДатаПринятияКИсполнению = ТекущаяДатаСеанса();
		КонецЕсли;
		
		Если  Ссылка.Пустая() Тогда
			СформироватьУведомлениеОСобытии();
		КонецЕсли;
	КонецПроцедуры
	
	Процедура ОбработкаЗаполнения(ДанныеЗаполнения)
		
		Если ТипЗнч(ДанныеЗаполнения) = Тип("ЗадачаОбъект.ЗадачаИсполнителя") Тогда
			ЗаполнитьЗначенияСвойств(ЭтотОбъект, ДанныеЗаполнения, 
			"БизнесПроцесс,ТочкаМаршрута,Наименование,Исполнитель,РольИсполнителя,ОсновнойОбъектАдресации," 
			+ "ДополнительныйОбъектАдресации,Важность,ДатаИсполнения,Автор,Описание,СрокИсполнения," 
			+ "ДатаНачала,РезультатВыполнения,Предмет");
			Дата = ТекущаяДатаСеанса();
		КонецЕсли;
		Если НЕ ЗначениеЗаполнено(Важность) Тогда
			Важность = Перечисления.ВариантыВажностиЗадачи.Обычная;
		КонецЕсли;
		
		Если НЕ ЗначениеЗаполнено(СостояниеБизнесПроцесса) Тогда
			СостояниеБизнесПроцесса = Перечисления.СостоянияБизнесПроцессов.Активен;
		КонецЕсли;
		
	КонецПроцедуры
	
	#КонецОбласти
	
	#Область СлужебныеПроцедурыИФункции
	
	Процедура УстановитьСостояниеПодчиненныхБизнесПроцессов(НовоеСостояние)
		
		НачатьТранзакцию();
		Попытка
			ПодчиненныеБизнесПроцессы = БизнесПроцессыИЗадачиСервер.БизнесПроцессыГлавнойЗадачи(Ссылка, Истина);
			
			Если ПодчиненныеБизнесПроцессы <> Неопределено Тогда
				Для Каждого ПодчиненныйБизнесПроцесс Из ПодчиненныеБизнесПроцессы Цикл
					БизнесПроцессОбъект = ПодчиненныйБизнесПроцесс.ПолучитьОбъект();
					БизнесПроцессОбъект.Заблокировать();
					БизнесПроцессОбъект.Состояние = НовоеСостояние;
					БизнесПроцессОбъект.Записать();
				КонецЦикла;	
			КонецЕсли;	
			ЗафиксироватьТранзакцию();
		Исключение
			ОтменитьТранзакцию();
			ВызватьИсключение;
		КонецПопытки;
		
	КонецПроцедуры
	
Функция СформироватьУведомлениеОСобытии()
	Попытка
	СписокЯщиковДляРассылки = ПолучитьСписокЯщиковДляУведомления();
	
	Для Каждого Строка из СписокЯщиковДляРассылки цикл
		
		ЭлПисьмо = Документы.ЭлектронноеПисьмо.СоздатьДокумент();
		ЭлПисьмо.УстановитьНовыйНомер();
		ЭлПисьмо.УчетнаяЗапись  	 		= Справочники.УчетныеЗаписиЭлектроннойПочты.НайтиПоКоду("000000001");
		ЭлПисьмо.Дата				 		= ТекущаяДата();
		ЭлПисьмо.ДатаОтправления	 		= ТекущаяДата();
		ЭлПисьмо.Ответственный	 			= ПараметрыСеанса.ТекущийПользователь;
		ЭлПисьмо.ОтправительАдресЭлектроннойПочты = ЭлПисьмо.УчетнаяЗапись.АдресЭлектроннойПочты;
		ЭлПисьмо.ОтправительПредставление 	= "Система відправки повідомлень"; 
		ЭлПисьмо.ОтправительИмя           	= "Система відправки повідомлень";
		ЭлПисьмо.ОтправительПредставление 	= ЭлПисьмо.УчетнаяЗапись.АдресЭлектроннойПочты;
		ЭлПисьмо.Уведомление				= Истина;
		
		КомуСтрока						 = ЭлПисьмо.КомуТЧ.Добавить();
		КомуСтрока.АдресЭлектроннойПочты = Строка.КонтактнаяИнформация;
		КомуСтрока.Представление		 = Строка.Пользователь;
		
		ЭлПисьмо.Кому 				= Строка.КонтактнаяИнформация;
		ЭлПисьмо.КомуПредставление  = Строка.Пользователь;
		ЭлПисьмо.ВидТекстаПисьма 	= Перечисления.ВидыТекстовЭлектронныхПисем.HTML;
		ЭлПисьмо.ЗаголовокПисьма 	= ?(ТипЗнч(Предмет) = тип("ДокументСсылка.ЗаявкаНаРасходованиеСредств"),"Повідомлення про необхідність погодити заявку № " + Предмет.Номер,"Повідомлення про необхідність погодити реєстр № " + Предмет.Номер);
		ЭлПисьмо.Тема            	= ?(ТипЗнч(Предмет) = тип("ДокументСсылка.ЗаявкаНаРасходованиеСредств"),"Повідомлення про необхідність погодити заявку № " + Предмет.Номер,"Повідомлення про необхідність погодити реєстр № " + Предмет.Номер);	
		ЭлПисьмо.ТекстПисьма	 	= ?(ТипЗнч(Предмет) = тип("ДокументСсылка.ЗаявкаНаРасходованиеСредств"),СформироватьТекстПисьмаЗаявка(Предмет.Номер,Предмет.Комментарий,Предмет.СуммаДокумента,Предмет.Ответственный,Строка.Пользователь),СформироватьТекстПисьмаРеестр(Предмет.Номер,"Реєстр на сплату",Предмет.ЗаявкиНаРасходованиеДС.Итог("СуммаКОплате"),Предмет.Ответственный,Строка.Пользователь));	
		
		ЭлПисьмо.УчетнаяЗапись   = Справочники.УчетныеЗаписиЭлектроннойПочты.НайтиПоКоду("000000001");
		ЭлПисьмо.Записать();
	КонецЦикла;
	
Исключение
	
	ЗаписьЖурналаРегистрации("Ошибка при формировании письма по уведомлениям",УровеньЖурналаРегистрации.Ошибка,,,ИнформацияОбОшибке(),);
	
	КонецПопытки;
КонецФункции

Функция ПолучитьСписокЯщиковДляУведомления()
	
	Запрос = новый Запрос;
	Запрос.Текст = "ВЫБРАТЬ
	               |	КонтактнаяИнформация.Представление КАК КонтактнаяИнформация,
	               |	ИсполнителиЗадач.Исполнитель.Наименование КАК Пользователь
	               |ИЗ
	               |	РегистрСведений.ИсполнителиЗадач КАК ИсполнителиЗадач
	               |		ЛЕВОЕ СОЕДИНЕНИЕ РегистрСведений.КонтактнаяИнформация КАК КонтактнаяИнформация
	               |		ПО ИсполнителиЗадач.Исполнитель = КонтактнаяИнформация.Объект
	               |ГДЕ
	               |	ИсполнителиЗадач.РольИсполнителя = &РольИсполнителя
	               |	И ИсполнителиЗадач.ОсновнойОбъектАдресации = &ОсновнойОбъектАдресации
	               |	И КонтактнаяИнформация.Тип = &Тип
	               |	И КонтактнаяИнформация.Вид = &Вид";
	Запрос.УстановитьПараметр("РольИсполнителя",РольИсполнителя);
	Запрос.УстановитьПараметр("ОсновнойОбъектАдресации",ОсновнойОбъектАдресации);
	Запрос.УстановитьПараметр("Тип",Перечисления.ТипыКонтактнойИнформации.АдресЭлектроннойПочты);
	Запрос.УстановитьПараметр("Вид",Справочники.ВидыКонтактнойИнформации.СлужебныйАдресЭлектроннойПочтыПользователя);
	
	Возврат Запрос.Выполнить().Выгрузить();
	
КонецФункции

Функция СформироватьТекстПисьмаЗаявка(НомерЗаявки,ОписаниеЗаявки,сумма,АвторЗаявки,пользователь)
ТекстПисьма = "<html><head>
|<meta http-equiv=""Content-Type"" content=""text/html; charset=utf-8"">
|<meta content=""MSHTML 6.00.2800.1400"" name=""GENERATOR""></head>
|<body><table class=""MsoNormalTable"" border=""0"" cellspacing=""0"" cellpadding=""0"" width=""100%"" style=""width:100.0%;background:#CCCCCC;border-collapse:collapse;mso-yfti-tbllook:
|1184;mso-padding-alt:0cm 0cm 0cm 0cm"">
|<tbody><tr>
|  <td style=""padding:18.75pt 18.75pt 18.75pt 18.75pt"">
|  <div align=""center"">
|  <table class=""MsoNormalTable"" border=""0"" cellspacing=""0"" cellpadding=""0"" width=""740"" style=""width:555.0pt;background:white;border-collapse:collapse;mso-yfti-tbllook:
|   1184;mso-padding-alt:0cm 0cm 0cm 0cm"">
|   <tbody><tr>
|    <td width=""90%"" valign=""top"" style=""width:90.0%;padding:0cm 0cm 0cm 0cm"">
|    <div align=""center"">
|    <table class=""MsoNormalTable"" border=""0"" cellspacing=""0"" cellpadding=""0"" width=""90%"" style=""width: 90%; border-collapse: collapse; background-position: initial initial; background-repeat: initial initial;"">
|     <tbody><tr>
|      <td width=""45%"" style=""width:45.0%;padding:0cm 0cm 0cm 0cm"">
|      <p class=""MsoNormal"" style=""margin-top:18.75pt;margin-right:0cm;margin-bottom:
|      11.25pt;margin-left:0cm""><span style=""mso-fareast-font-family:&quot;Times New Roman&quot;;
|      mso-no-proof:yes;text-decoration:none;text-underline:none""><!--[if gte vml 1]><v:shapetype
|       id=""_x0000_t75"" coordsize=""21600,21600"" o:spt=""75"" o:preferrelative=""t""
|       path=""m@4@5l@4@11@9@11@9@5xe"" filled=""f"" stroked=""f"">
|       <v:stroke joinstyle=""miter""/>
|       <v:formulas>
|        <v:f eqn=""if lineDrawn pixelLineWidth 0""/>
|        <v:f eqn=""sum @0 1 0""/>
|        <v:f eqn=""sum 0 0 @1""/>
|        <v:f eqn=""prod @2 1 2""/>
|        <v:f eqn=""prod @3 21600 pixelWidth""/>
|        <v:f eqn=""prod @3 21600 pixelHeight""/>
|        <v:f eqn=""sum @0 0 1""/>
|        <v:f eqn=""prod @6 1 2""/>
|        <v:f eqn=""prod @7 21600 pixelWidth""/>
|        <v:f eqn=""sum @8 21600 0""/>
|        <v:f eqn=""prod @7 21600 pixelHeight""/>
|        <v:f eqn=""sum @10 21600 0""/>
|       </v:formulas>
|       <v:path o:extrusionok=""f"" gradientshapeok=""t"" o:connecttype=""rect""/>
|       <o:lock v:ext=""edit"" aspectratio=""t""/>
|      </v:shapetype><v:shape id=""_x0000_i1032"" type=""#_x0000_t75"" style='width:118.5pt;
|       height:41.25pt;visibility:visible'>
|         </v:shape><![endif]--></span><o:p></o:p></p>
|      </td>
|      <td width=""55%"" style=""width:55.0%;padding:1cm 0cm 0cm 0cm"">
//|<img src=""C:\VR\Email\Logo_Vechir-02.png"" style="" width:100px;height:120px;&quot;"" =""""="""">
|</td>
|     </tr>
|    </tbody></table>
|    </div>
|    <p class=""MsoNormal"" align=""center"" style=""text-align:center""><span style=""mso-fareast-font-family:&quot;Times New Roman&quot;;display:none;mso-hide:
|    all""><o:p>&nbsp;</o:p></span></p>
|    <div align=""center"">
|    <table class=""MsoNormalTable"" border=""1"" cellspacing=""0"" cellpadding=""0"" width=""90%"" style=""width: 90%; border-collapse: collapse; border: none; background-position: initial initial; background-repeat: initial initial;"">
|     <tbody><tr>
|      <td width=""100%"" valign=""top"" style=""width:100.0%;border:none;border-top:
|      solid #CCCCCC 1.0pt;mso-border-top-alt:solid #CCCCCC .75pt;padding:18.75pt 0cm 0cm 0cm""><!-- Bold text (Dear) -->
|      <table class=""MsoNormalTable"" border=""0"" cellspacing=""0"" cellpadding=""0"" style=""border-collapse:collapse;mso-yfti-tbllook:1184;mso-padding-alt:
|       0cm 0cm 0cm 0cm"">
|       <tbody><tr>
|        <td style=""padding:0cm 0cm 0cm 0cm"">
|        <p style=""margin-top:7.5pt;line-height:16.5pt""><b><span style=""font-size:11.5pt;font-family:&quot;Arial&quot;,sans-serif;color:#333333"">Вітаємо,
|        #Пользователь,<o:p></o:p></span></b></p>
|        </td>
|       </tr>
|      </tbody></table>
|<!-- Paragraph -->
|      <p class=""MsoNormal""><span style=""mso-fareast-font-family:&quot;Times New Roman&quot;;
|      display:none;mso-hide:all""><o:p>&nbsp;</o:p></span></p>
|      <table class=""MsoNormalTable"" border=""0"" cellspacing=""0"" cellpadding=""0"" style=""border-collapse:collapse;mso-yfti-tbllook:1184;mso-padding-alt:
|       0cm 0cm 0cm 0cm"">
|       <tbody><tr>
|        <td style=""padding:0cm 0cm 0cm 0cm"">
|        <p style=""margin-top:7.5pt;line-height:16.5pt""><font color=""#333333"" face=""Arial, sans-serif""><span style=""caret-color: rgb(51, 51, 51); font-size: 15.333333015441895px;"">Вам потрібно погодити заявку на витрату коштів</span></font></p></td></tr></tbody></table>
|<!-- Paragraph -->
|      <p class=""MsoNormal""><span style=""mso-fareast-font-family:&quot;Times New Roman&quot;;
|      display:none;mso-hide:all""><o:p>&nbsp;</o:p></span></p>
|      <table class=""MsoNormalTable"" border=""0"" cellspacing=""0"" cellpadding=""0"" style=""border-collapse:collapse;mso-yfti-tbllook:1184;mso-padding-alt:
|       0cm 0cm 0cm 0cm"">
|       <tbody><tr>
|        <td style=""padding:0cm 0cm 0cm 0cm""><p style=""margin-top:7.5pt;line-height:16.5pt""><font color=""#333333"" face=""Arial, sans-serif""><span style=""caret-color: rgb(51, 51, 51); font-size: 15.333333015441895px;"">Нижче наведено докладну інформацію</span></font><span style=""font-size:
|        11.5pt;font-family:&quot;Arial&quot;,sans-serif;color:#333333"">: <o:p></o:p></span></p>
|        </td>
|       </tr>
|      </tbody></table>
|<!-- Data in Table  format -->
|      <p class=""MsoNormal""><span style=""mso-fareast-font-family:&quot;Times New Roman&quot;;
|      display:none;mso-hide:all""><o:p>&nbsp;</o:p></span></p>
|      <table class=""MsoNormalTable"" border=""0"" cellspacing=""0"" cellpadding=""0"" style=""border-collapse:collapse;mso-yfti-tbllook:1184;mso-padding-alt:
|       0cm 0cm 0cm 0cm"">
|       <tbody><tr>
|        <td style=""padding:15.0pt 0cm 15.0pt 0cm"">
|        <table class=""MsoNormalTable"" border=""0"" cellspacing=""0"" cellpadding=""0"" style=""background:#F1F1F1;border-collapse:collapse;mso-yfti-tbllook:
|         1184;mso-padding-alt:0cm 0cm 0cm 0cm"">
|         <tbody><tr>
|          <td style=""border:none;border-bottom:solid #DDDDDD 1.0pt;mso-border-bottom-alt:
|          solid #DDDDDD .75pt;padding:7.5pt 11.25pt 7.5pt 11.25pt"">
|          <p class=""MsoNormal"" style=""line-height:16.5pt""><b><span style=""font-size:10.5pt;font-family:&quot;Arial&quot;,sans-serif;mso-fareast-font-family:
|          &quot;Times New Roman&quot;;color:#333333"">Номер заявки<o:p></o:p></span></b></p>
|          </td>
|          <td style=""border:none;border-bottom:solid #DDDDDD 1.0pt;mso-border-bottom-alt:
|          solid #DDDDDD .75pt;padding:7.5pt 11.25pt 7.5pt 11.25pt"">
|         <p class=""MsoNormal"" style=""line-height:16.5pt""><span style=""font-size:
|         11.5pt;font-family:&quot;Arial&quot;,sans-serif;mso-fareast-font-family:&quot;Times New Roman&quot;;
|         color:#333333"">#Номер<o:p></o:p></span></p>
|         </td>
|        </tr>
|        <tr>
|         <td style=""border:none;border-bottom:solid #DDDDDD 1.0pt;mso-border-bottom-alt:
|         solid #DDDDDD .75pt;padding:7.5pt 11.25pt 7.5pt 11.25pt"">
|         <p class=""MsoNormal"" style=""line-height:16.5pt""><b><span style=""font-size:10.5pt;font-family:&quot;Arial&quot;,sans-serif;mso-fareast-font-family:
|         &quot;Times New Roman&quot;;color:#333333"">Сума<o:p></o:p></span></b></p>
|         </td>
|         <td style=""border:none;border-bottom:solid #DDDDDD 1.0pt;mso-border-bottom-alt:
|         solid #DDDDDD .75pt;padding:7.5pt 11.25pt 7.5pt 11.25pt"">
|         <p class=""MsoNormal"" style=""line-height:16.5pt""><span style=""font-size:
|         10.5pt;font-family:&quot;Arial&quot;,sans-serif;mso-fareast-font-family:&quot;Times New Roman&quot;;
|         color:#333333"">#Сума<o:p></o:p></span></p>
|         </td>
|        </tr>
|        <tr>
|         <td style=""border:none;border-bottom:solid #DDDDDD 1.0pt;mso-border-bottom-alt:
|         solid #DDDDDD .75pt;padding:7.5pt 11.25pt 7.5pt 11.25pt"">
|         <p class=""MsoNormal"" style=""line-height:16.5pt""><b><span style=""font-size:10.5pt;font-family:&quot;Arial&quot;,sans-serif;mso-fareast-font-family:
|         &quot;Times New Roman&quot;;color:#333333"">Опис<o:p></o:p></span></b></p>
|         </td>
|         <td style=""border:none;border-bottom:solid #DDDDDD 1.0pt;mso-border-bottom-alt:
|         solid #DDDDDD .75pt;padding:7.5pt 11.25pt 7.5pt 11.25pt"">
|         <p class=""MsoNormal"" style=""line-height:16.5pt""><span style=""font-size:
|          10.5pt;font-family:&quot;Arial&quot;,sans-serif;mso-fareast-font-family:&quot;Times New Roman&quot;;
|          color:#333333"">#Опис<o:p></o:p></span></p>
|          </td>
|         </tr>
|         <tr>
|          <td style=""border:none;border-bottom:solid #DDDDDD 1.0pt;mso-border-bottom-alt:
|          solid #DDDDDD .75pt;padding:7.5pt 11.25pt 7.5pt 11.25pt"">
|          <p class=""MsoNormal"" style=""line-height:16.5pt""><b><span style=""font-size:10.5pt;font-family:&quot;Arial&quot;,sans-serif;mso-fareast-font-family:
|          &quot;Times New Roman&quot;;color:#333333"">Автор<o:p></o:p></span></b></p>
|          </td>
|          <td style=""border:none;border-bottom:solid #DDDDDD 1.0pt;mso-border-bottom-alt:
|          solid #DDDDDD .75pt;padding:7.5pt 11.25pt 7.5pt 11.25pt"">
|          <p class=""MsoNormal"" style=""line-height:16.5pt""><span style=""font-size:
|          10.5pt;font-family:&quot;Arial&quot;,sans-serif;mso-fareast-font-family:&quot;Times New Roman&quot;;
|          color:#333333"">#Автор<o:p></o:p></span></p>
|          </td>
|         </tr>
|        </tbody></table>
|        </td>
|       </tr>
|      </tbody></table>
|      </td>
|     </tr>
|     <tr>
|      <td style=""border:none;padding:0cm 0cm 0cm 0cm"">
|      <table class=""MsoNormalTable"" border=""0"" cellspacing=""0"" cellpadding=""0"" width=""100%"" style=""width:100.0%;border-collapse:collapse;mso-yfti-tbllook:
|       1184;mso-padding-alt:0cm 0cm 0cm 0cm"">
|       <tbody><tr>
|        <td width=""100%"" valign=""top"" style=""width: 100%; padding: 0cm; background-position: initial initial; background-repeat: initial initial;"">
|       <table class=""MsoNormalTable"" border=""0"" cellspacing=""0"" cellpadding=""0"" width=""100%"" style=""width:100.0%;border-collapse:collapse;mso-yfti-tbllook:
|         1184;mso-padding-alt:0cm 0cm 0cm 0cm"">
|         <tbody><tr>
|          <td style=""padding:0cm 0cm 0cm 0cm"">
|          <p class=""MsoNormal"">&nbsp;<o:p></o:p></p>
|          </td>
|         </tr>
|         <tr>
|          <td style=""padding:0cm 0cm 0cm 0cm"">
|          <p class=""MsoNormal"">&nbsp;<o:p></o:p></p>
|          </td>
|         </tr>
|         <tr>
|          <td style=""padding:0cm 0cm 0cm 0cm"">
|          <p style=""line-height:14.25pt""><font color=""#333333"" face=""Arial, sans-serif""><span style=""font-size: 11.5pt;"">Якщо у вас залишились питання, Ви завжди маєте можливість&nbsp;</span><span style=""caret-color: rgb(51, 51, 51); font-size: 15.333333015441895px;"">зв'язатися</span><span style=""font-size: 11.5pt;"">&nbsp;с нами</span></font><span style=""font-size:11.5pt;font-family:&quot;Arial&quot;,sans-serif;color:#333333"">.<o:p></o:p></span></p>
|          <p class=""MsoNormal"" style=""margin-bottom:12.0pt;line-height:14.25pt""><span style=""font-size:11.5pt;font-family:&quot;Arial&quot;,sans-serif;mso-fareast-font-family:
|          &quot;Times New Roman&quot;;color:#333333"">&nbsp;</span></p>
|          <p style=""line-height:14.25pt""><span style=""font-size:11.5pt;
|          font-family:&quot;Arial&quot;,sans-serif;color:#333333"">Дякуємо,<br>
|          Автомитична система повідомлень&nbsp;<o:p></o:p></span></p>
|          </td>
|         </tr>
|        </tbody></table>
|        <p class=""MsoNormal""><span style=""mso-fareast-font-family:&quot;Times New Roman&quot;;
|        display:none;mso-hide:all""><o:p>&nbsp;</o:p></span></p>
|        <table class=""MsoNormalTable"" border=""0"" cellspacing=""0"" cellpadding=""0"" width=""100%"" style=""width: 100%; border-collapse: collapse; background-position: initial initial; background-repeat: initial initial;"">
|         <tbody><tr>
|          <td width=""100%"" style=""width:100.0%;padding:7.5pt 0cm 0cm 0cm"">
|          <table class=""MsoNormalTable"" border=""0"" cellspacing=""0"" cellpadding=""0"" style=""border-collapse:collapse;mso-yfti-tbllook:1184;mso-padding-alt:
|           0cm 0cm 15.0pt 0cm"">
|           <tbody><tr>
|            <td style=""padding:0cm 0cm 15.0pt 0cm"">
|            <p class=""MsoNormal"" align=""center"" style=""margin-bottom:7.5pt;
|            text-align:center""><o:p></o:p></p>
|            </td>
|            <td style=""padding:0cm 0cm 15.0pt 0cm"">
|            <p class=""MsoNormal"" align=""center"" style=""margin-bottom:7.5pt;
|            text-align:center""><o:p></o:p></p>
|            </td>
|            <td style=""padding:0cm 0cm 15.0pt 0cm"">
|            <p class=""MsoNormal"" align=""center"" style=""margin-bottom:7.5pt;
|            text-align:center""><o:p></o:p></p>
|            </td>
|            <td style=""padding:0cm 0cm 15.0pt 0cm"">
|            <p class=""MsoNormal"" align=""center"" style=""margin-bottom:7.5pt;
|            text-align:center""><o:p></o:p></p>
|            </td>
|            <td style=""padding:0cm 0cm 15.0pt 0cm"">
|            <p class=""MsoNormal"" align=""center"" style=""margin-bottom:7.5pt;
|            text-align:center""><o:p></o:p></p>
|            </td>
|            <td style=""padding:0cm 0cm 15.0pt 0cm"">
|            <p class=""MsoNormal"" align=""center"" style=""margin-bottom:7.5pt;
|            text-align:center""><o:p></o:p></p>
|            </td>
|            <td style=""padding:0cm 0cm 15.0pt 0cm"">
|            <p class=""MsoNormal"" align=""center"" style=""margin-bottom:7.5pt;
|            text-align:center""><o:p></o:p></p>
|            </td>
|           </tr>
|          </tbody></table>
|          </td>
|         </tr>
|        </tbody></table>
|        </td>
|       </tr>
|      </tbody></table>
|      </td>
|     </tr>
|    </tbody></table>
|    </div>
|    <p class=""MsoNormal"" align=""center"" style=""text-align:center""><span style=""mso-fareast-font-family:&quot;Times New Roman&quot;;display:none;mso-hide:
|    all""><o:p>&nbsp;</o:p></span></p>
|    <div align=""center""><br>
|    </div>
|    </td>
|   </tr>
| </tbody></table>
|  </div>
|  </td>
| </tr></tbody></table></body></html>";


ТекстПисьма = СтрЗаменить(ТекстПисьма,"#Номер",НомерЗаявки);
ТекстПисьма = СтрЗаменить(ТекстПисьма,"#Сума",СтрЗаменить(сумма,Символы.НПП,"")+" "+Предмет.ВалютаДокумента);
ТекстПисьма = СтрЗаменить(ТекстПисьма,"#Опис",ОписаниеЗаявки);
ТекстПисьма = СтрЗаменить(ТекстПисьма,"#Автор",АвторЗаявки);
ТекстПисьма = СтрЗаменить(ТекстПисьма,"#Пользователь",Пользователь);

Возврат  ТекстПисьма;
КонецФункции


Функция СформироватьТекстПисьмаРеестр(НомерЗаявки,ОписаниеЗаявки,сумма,АвторЗаявки,Пользователь)
ТекстПисьма = "<html><head>
|<meta http-equiv=""Content-Type"" content=""text/html; charset=utf-8"">
|<meta content=""MSHTML 6.00.2800.1400"" name=""GENERATOR""></head>
|<body><table class=""MsoNormalTable"" border=""0"" cellspacing=""0"" cellpadding=""0"" width=""100%"" style=""width:100.0%;background:#CCCCCC;border-collapse:collapse;mso-yfti-tbllook:
|1184;mso-padding-alt:0cm 0cm 0cm 0cm"">
|<tbody><tr>
|  <td style=""padding:18.75pt 18.75pt 18.75pt 18.75pt"">
|  <div align=""center"">
|  <table class=""MsoNormalTable"" border=""0"" cellspacing=""0"" cellpadding=""0"" width=""740"" style=""width:555.0pt;background:white;border-collapse:collapse;mso-yfti-tbllook:
|   1184;mso-padding-alt:0cm 0cm 0cm 0cm"">
|   <tbody><tr>
|    <td width=""90%"" valign=""top"" style=""width:90.0%;padding:0cm 0cm 0cm 0cm"">
|    <div align=""center"">
|    <table class=""MsoNormalTable"" border=""0"" cellspacing=""0"" cellpadding=""0"" width=""90%"" style=""width: 90%; border-collapse: collapse; background-position: initial initial; background-repeat: initial initial;"">
|     <tbody><tr>
|      <td width=""45%"" style=""width:45.0%;padding:0cm 0cm 0cm 0cm"">
|      <p class=""MsoNormal"" style=""margin-top:18.75pt;margin-right:0cm;margin-bottom:
|      11.25pt;margin-left:0cm""><span style=""mso-fareast-font-family:&quot;Times New Roman&quot;;
|      mso-no-proof:yes;text-decoration:none;text-underline:none""><!--[if gte vml 1]><v:shapetype
|       id=""_x0000_t75"" coordsize=""21600,21600"" o:spt=""75"" o:preferrelative=""t""
|       path=""m@4@5l@4@11@9@11@9@5xe"" filled=""f"" stroked=""f"">
|       <v:stroke joinstyle=""miter""/>
|       <v:formulas>
|        <v:f eqn=""if lineDrawn pixelLineWidth 0""/>
|        <v:f eqn=""sum @0 1 0""/>
|        <v:f eqn=""sum 0 0 @1""/>
|        <v:f eqn=""prod @2 1 2""/>
|        <v:f eqn=""prod @3 21600 pixelWidth""/>
|        <v:f eqn=""prod @3 21600 pixelHeight""/>
|        <v:f eqn=""sum @0 0 1""/>
|        <v:f eqn=""prod @6 1 2""/>
|        <v:f eqn=""prod @7 21600 pixelWidth""/>
|        <v:f eqn=""sum @8 21600 0""/>
|        <v:f eqn=""prod @7 21600 pixelHeight""/>
|        <v:f eqn=""sum @10 21600 0""/>
|       </v:formulas>
|       <v:path o:extrusionok=""f"" gradientshapeok=""t"" o:connecttype=""rect""/>
|       <o:lock v:ext=""edit"" aspectratio=""t""/>
|      </v:shapetype><v:shape id=""_x0000_i1032"" type=""#_x0000_t75"" style='width:118.5pt;
|       height:41.25pt;visibility:visible'>
|         </v:shape><![endif]--></span><o:p></o:p></p>
|      </td>
|      <td width=""55%"" style=""width:55.0%;padding:1cm 0cm 0cm 0cm"">
//|<img src=""C:\VR\Email\Logo_Vechir-02.png"" style="" width:100px;height:120px;&quot;"" =""""="""">
|</td>
|     </tr>
|    </tbody></table>
|    </div>
|    <p class=""MsoNormal"" align=""center"" style=""text-align:center""><span style=""mso-fareast-font-family:&quot;Times New Roman&quot;;display:none;mso-hide:
|    all""><o:p>&nbsp;</o:p></span></p>
|    <div align=""center"">
|    <table class=""MsoNormalTable"" border=""1"" cellspacing=""0"" cellpadding=""0"" width=""90%"" style=""width: 90%; border-collapse: collapse; border: none; background-position: initial initial; background-repeat: initial initial;"">
|     <tbody><tr>
|      <td width=""100%"" valign=""top"" style=""width:100.0%;border:none;border-top:
|      solid #CCCCCC 1.0pt;mso-border-top-alt:solid #CCCCCC .75pt;padding:18.75pt 0cm 0cm 0cm""><!-- Bold text (Dear) -->
|      <table class=""MsoNormalTable"" border=""0"" cellspacing=""0"" cellpadding=""0"" style=""border-collapse:collapse;mso-yfti-tbllook:1184;mso-padding-alt:
|       0cm 0cm 0cm 0cm"">
|       <tbody><tr>
|        <td style=""padding:0cm 0cm 0cm 0cm"">
|        <p style=""margin-top:7.5pt;line-height:16.5pt""><b><span style=""font-size:11.5pt;font-family:&quot;Arial&quot;,sans-serif;color:#333333"">Вітаємо,
|        #Пользователь,<o:p></o:p></span></b></p>
|        </td>
|       </tr>
|      </tbody></table>
|<!-- Paragraph -->
|      <p class=""MsoNormal""><span style=""mso-fareast-font-family:&quot;Times New Roman&quot;;
|      display:none;mso-hide:all""><o:p>&nbsp;</o:p></span></p>
|      <table class=""MsoNormalTable"" border=""0"" cellspacing=""0"" cellpadding=""0"" style=""border-collapse:collapse;mso-yfti-tbllook:1184;mso-padding-alt:
|       0cm 0cm 0cm 0cm"">
|       <tbody><tr>
|        <td style=""padding:0cm 0cm 0cm 0cm"">
|        <p style=""margin-top:7.5pt;line-height:16.5pt""><font color=""#333333"" face=""Arial, sans-serif""><span style=""caret-color: rgb(51, 51, 51); font-size: 15.333333015441895px;"">Вам потрібно погодити реєстр на витрату коштів</span></font></p></td></tr></tbody></table>
|<!-- Paragraph -->
|      <p class=""MsoNormal""><span style=""mso-fareast-font-family:&quot;Times New Roman&quot;;
|      display:none;mso-hide:all""><o:p>&nbsp;</o:p></span></p>
|      <table class=""MsoNormalTable"" border=""0"" cellspacing=""0"" cellpadding=""0"" style=""border-collapse:collapse;mso-yfti-tbllook:1184;mso-padding-alt:
|       0cm 0cm 0cm 0cm"">
|       <tbody><tr>
|        <td style=""padding:0cm 0cm 0cm 0cm""><p style=""margin-top:7.5pt;line-height:16.5pt""><font color=""#333333"" face=""Arial, sans-serif""><span style=""caret-color: rgb(51, 51, 51); font-size: 15.333333015441895px;"">Нижче наведено докладну інформацію</span></font><span style=""font-size:
|        11.5pt;font-family:&quot;Arial&quot;,sans-serif;color:#333333"">: <o:p></o:p></span></p>
|        </td>
|       </tr>
|      </tbody></table>
|<!-- Data in Table  format -->
|      <p class=""MsoNormal""><span style=""mso-fareast-font-family:&quot;Times New Roman&quot;;
|      display:none;mso-hide:all""><o:p>&nbsp;</o:p></span></p>
|      <table class=""MsoNormalTable"" border=""0"" cellspacing=""0"" cellpadding=""0"" style=""border-collapse:collapse;mso-yfti-tbllook:1184;mso-padding-alt:
|       0cm 0cm 0cm 0cm"">
|       <tbody><tr>
|        <td style=""padding:15.0pt 0cm 15.0pt 0cm"">
|        <table class=""MsoNormalTable"" border=""0"" cellspacing=""0"" cellpadding=""0"" style=""background:#F1F1F1;border-collapse:collapse;mso-yfti-tbllook:
|         1184;mso-padding-alt:0cm 0cm 0cm 0cm"">
|         <tbody><tr>
|          <td style=""border:none;border-bottom:solid #DDDDDD 1.0pt;mso-border-bottom-alt:
|          solid #DDDDDD .75pt;padding:7.5pt 11.25pt 7.5pt 11.25pt"">
|          <p class=""MsoNormal"" style=""line-height:16.5pt""><b><span style=""font-size:10.5pt;font-family:&quot;Arial&quot;,sans-serif;mso-fareast-font-family:
|          &quot;Times New Roman&quot;;color:#333333"">Номер реєстра<o:p></o:p></span></b></p>
|          </td>
|          <td style=""border:none;border-bottom:solid #DDDDDD 1.0pt;mso-border-bottom-alt:
|          solid #DDDDDD .75pt;padding:7.5pt 11.25pt 7.5pt 11.25pt"">
|         <p class=""MsoNormal"" style=""line-height:16.5pt""><span style=""font-size:
|         11.5pt;font-family:&quot;Arial&quot;,sans-serif;mso-fareast-font-family:&quot;Times New Roman&quot;;
|         color:#333333"">#Номер<o:p></o:p></span></p>
|         </td>
|        </tr>
|        <tr>
|         <td style=""border:none;border-bottom:solid #DDDDDD 1.0pt;mso-border-bottom-alt:
|         solid #DDDDDD .75pt;padding:7.5pt 11.25pt 7.5pt 11.25pt"">
|         <p class=""MsoNormal"" style=""line-height:16.5pt""><b><span style=""font-size:10.5pt;font-family:&quot;Arial&quot;,sans-serif;mso-fareast-font-family:
|         &quot;Times New Roman&quot;;color:#333333"">Сума<o:p></o:p></span></b></p>
|         </td>
|         <td style=""border:none;border-bottom:solid #DDDDDD 1.0pt;mso-border-bottom-alt:
|         solid #DDDDDD .75pt;padding:7.5pt 11.25pt 7.5pt 11.25pt"">
|         <p class=""MsoNormal"" style=""line-height:16.5pt""><span style=""font-size:
|         10.5pt;font-family:&quot;Arial&quot;,sans-serif;mso-fareast-font-family:&quot;Times New Roman&quot;;
|         color:#333333"">#Сума<o:p></o:p></span></p>
|         </td>
|        </tr>
|        <tr>
//|         <td style=""border:none;border-bottom:solid #DDDDDD 1.0pt;mso-border-bottom-alt:
//|         solid #DDDDDD .75pt;padding:7.5pt 11.25pt 7.5pt 11.25pt"">
//|         <p class=""MsoNormal"" style=""line-height:16.5pt""><b><span style=""font-size:10.5pt;font-family:&quot;Arial&quot;,sans-serif;mso-fareast-font-family:
//|         &quot;Times New Roman&quot;;color:#333333"">Опис<o:p></o:p></span></b></p>
//|         </td>
//|         <td style=""border:none;border-bottom:solid #DDDDDD 1.0pt;mso-border-bottom-alt:
//|         solid #DDDDDD .75pt;padding:7.5pt 11.25pt 7.5pt 11.25pt"">
//|         <p class=""MsoNormal"" style=""line-height:16.5pt""><span style=""font-size:
//|          10.5pt;font-family:&quot;Arial&quot;,sans-serif;mso-fareast-font-family:&quot;Times New Roman&quot;;
//|          color:#333333"">#Опис<o:p></o:p></span></p>
//|          </td>
|         </tr>
|         <tr>
|          <td style=""border:none;border-bottom:solid #DDDDDD 1.0pt;mso-border-bottom-alt:
|          solid #DDDDDD .75pt;padding:7.5pt 11.25pt 7.5pt 11.25pt"">
|          <p class=""MsoNormal"" style=""line-height:16.5pt""><b><span style=""font-size:10.5pt;font-family:&quot;Arial&quot;,sans-serif;mso-fareast-font-family:
|          &quot;Times New Roman&quot;;color:#333333"">Автор<o:p></o:p></span></b></p>
|          </td>
|          <td style=""border:none;border-bottom:solid #DDDDDD 1.0pt;mso-border-bottom-alt:
|          solid #DDDDDD .75pt;padding:7.5pt 11.25pt 7.5pt 11.25pt"">
|          <p class=""MsoNormal"" style=""line-height:16.5pt""><span style=""font-size:
|          10.5pt;font-family:&quot;Arial&quot;,sans-serif;mso-fareast-font-family:&quot;Times New Roman&quot;;
|          color:#333333"">#Автор<o:p></o:p></span></p>
|          </td>
|         </tr>
|        </tbody></table>
|        </td>
|       </tr>
|      </tbody></table>
|      </td>
|     </tr>
|     <tr>
|      <td style=""border:none;padding:0cm 0cm 0cm 0cm"">
|      <table class=""MsoNormalTable"" border=""0"" cellspacing=""0"" cellpadding=""0"" width=""100%"" style=""width:100.0%;border-collapse:collapse;mso-yfti-tbllook:
|       1184;mso-padding-alt:0cm 0cm 0cm 0cm"">
|       <tbody><tr>
|        <td width=""100%"" valign=""top"" style=""width: 100%; padding: 0cm; background-position: initial initial; background-repeat: initial initial;"">
|       <table class=""MsoNormalTable"" border=""0"" cellspacing=""0"" cellpadding=""0"" width=""100%"" style=""width:100.0%;border-collapse:collapse;mso-yfti-tbllook:
|         1184;mso-padding-alt:0cm 0cm 0cm 0cm"">
|         <tbody><tr>
|          <td style=""padding:0cm 0cm 0cm 0cm"">
|          <p class=""MsoNormal"">&nbsp;<o:p></o:p></p>
|          </td>
|         </tr>
|         <tr>
|          <td style=""padding:0cm 0cm 0cm 0cm"">
|          <p class=""MsoNormal"">&nbsp;<o:p></o:p></p>
|          </td>
|         </tr>
|         <tr>
|          <td style=""padding:0cm 0cm 0cm 0cm"">
|          <p style=""line-height:14.25pt""><font color=""#333333"" face=""Arial, sans-serif""><span style=""font-size: 11.5pt;"">Якщо у вас залишились питання, Ви завжди маєте можливість&nbsp;</span><span style=""caret-color: rgb(51, 51, 51); font-size: 15.333333015441895px;"">зв'язатися</span><span style=""font-size: 11.5pt;"">&nbsp;с нами</span></font><span style=""font-size:11.5pt;font-family:&quot;Arial&quot;,sans-serif;color:#333333"">.<o:p></o:p></span></p>
|          <p class=""MsoNormal"" style=""margin-bottom:12.0pt;line-height:14.25pt""><span style=""font-size:11.5pt;font-family:&quot;Arial&quot;,sans-serif;mso-fareast-font-family:
|          &quot;Times New Roman&quot;;color:#333333"">&nbsp;</span></p>
|          <p style=""line-height:14.25pt""><span style=""font-size:11.5pt;
|          font-family:&quot;Arial&quot;,sans-serif;color:#333333"">Дякуємо,<br>
|          Автомитична система повідомлень&nbsp;<o:p></o:p></span></p>
|          </td>
|         </tr>
|        </tbody></table>
|        <p class=""MsoNormal""><span style=""mso-fareast-font-family:&quot;Times New Roman&quot;;
|        display:none;mso-hide:all""><o:p>&nbsp;</o:p></span></p>
|        <table class=""MsoNormalTable"" border=""0"" cellspacing=""0"" cellpadding=""0"" width=""100%"" style=""width: 100%; border-collapse: collapse; background-position: initial initial; background-repeat: initial initial;"">
|         <tbody><tr>
|          <td width=""100%"" style=""width:100.0%;padding:7.5pt 0cm 0cm 0cm"">
|          <table class=""MsoNormalTable"" border=""0"" cellspacing=""0"" cellpadding=""0"" style=""border-collapse:collapse;mso-yfti-tbllook:1184;mso-padding-alt:
|           0cm 0cm 15.0pt 0cm"">
|           <tbody><tr>
|            <td style=""padding:0cm 0cm 15.0pt 0cm"">
|            <p class=""MsoNormal"" align=""center"" style=""margin-bottom:7.5pt;
|            text-align:center""><o:p></o:p></p>
|            </td>
|            <td style=""padding:0cm 0cm 15.0pt 0cm"">
|            <p class=""MsoNormal"" align=""center"" style=""margin-bottom:7.5pt;
|            text-align:center""><o:p></o:p></p>
|            </td>
|            <td style=""padding:0cm 0cm 15.0pt 0cm"">
|            <p class=""MsoNormal"" align=""center"" style=""margin-bottom:7.5pt;
|            text-align:center""><o:p></o:p></p>
|            </td>
|            <td style=""padding:0cm 0cm 15.0pt 0cm"">
|            <p class=""MsoNormal"" align=""center"" style=""margin-bottom:7.5pt;
|            text-align:center""><o:p></o:p></p>
|            </td>
|            <td style=""padding:0cm 0cm 15.0pt 0cm"">
|            <p class=""MsoNormal"" align=""center"" style=""margin-bottom:7.5pt;
|            text-align:center""><o:p></o:p></p>
|            </td>
|            <td style=""padding:0cm 0cm 15.0pt 0cm"">
|            <p class=""MsoNormal"" align=""center"" style=""margin-bottom:7.5pt;
|            text-align:center""><o:p></o:p></p>
|            </td>
|            <td style=""padding:0cm 0cm 15.0pt 0cm"">
|            <p class=""MsoNormal"" align=""center"" style=""margin-bottom:7.5pt;
|            text-align:center""><o:p></o:p></p>
|            </td>
|           </tr>
|          </tbody></table>
|          </td>
|         </tr>
|        </tbody></table>
|        </td>
|       </tr>
|      </tbody></table>
|      </td>
|     </tr>
|    </tbody></table>
|    </div>
|    <p class=""MsoNormal"" align=""center"" style=""text-align:center""><span style=""mso-fareast-font-family:&quot;Times New Roman&quot;;display:none;mso-hide:
|    all""><o:p>&nbsp;</o:p></span></p>
|    <div align=""center""><br>
|    </div>
|    </td>
|   </tr>
| </tbody></table>
|  </div>
|  </td>
| </tr></tbody></table></body></html>";


ТекстПисьма = СтрЗаменить(ТекстПисьма,"#Номер",НомерЗаявки);
ТекстПисьма = СтрЗаменить(ТекстПисьма,"#Сума",СтрЗаменить(сумма,Символы.НПП,""));
ТекстПисьма = СтрЗаменить(ТекстПисьма,"#Опис",ОписаниеЗаявки);
ТекстПисьма = СтрЗаменить(ТекстПисьма,"#Автор",АвторЗаявки);
ТекстПисьма = СтрЗаменить(ТекстПисьма,"#Пользователь",Пользователь);

Возврат  ТекстПисьма;
КонецФункции

#КонецОбласти
	
#КонецЕсли