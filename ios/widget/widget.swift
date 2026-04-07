import CoreLocation
import SwiftUI
import WidgetKit

enum WidgetWeatherState {
    case fresh
    case stale
    case missing
}

struct WidgetWeatherSnapshot {
    let tempValue: Int
    let weatherCode: Int
    let updatedAt: Date
}

struct TaskEntry: TimelineEntry {
    let date: Date
    let greeting: String
    let dateLabel: String
    let taskCountToday: Int
    let tasksCompletedToday: Int
    let nextTasks: [(title: String, alarm: String?)]
    let overdueCount: Int
    let weatherTempValue: Int?
    let weatherCode: Int?
    let weatherUpdatedAt: Date?
    let weatherState: WidgetWeatherState
}

private struct WidgetBaseData {
    let greeting: String
    let dateLabel: String
    let taskCountToday: Int
    let tasksCompletedToday: Int
    let nextTasks: [(title: String, alarm: String?)]
    let overdueCount: Int
}

struct TaskProvider: TimelineProvider {
    private let suiteName = "group.com.ammaross.dayflow"
    private let weatherRefreshMinutes = 60

    func placeholder(in context: Context) -> TaskEntry {
        TaskEntry(
            date: Date(),
            greeting: "Good morning",
            dateLabel: "Monday, Apr 6",
            taskCountToday: 3,
            tasksCompletedToday: 1,
            nextTasks: [
                (title: "Buy groceries", alarm: nil),
                (title: "Finish report", alarm: "5:29 PM"),
                (title: "Call dentist", alarm: nil),
            ],
            overdueCount: 0,
            weatherTempValue: 78,
            weatherCode: 0,
            weatherUpdatedAt: Date(),
            weatherState: .fresh
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (TaskEntry) -> Void) {
        let defaults = UserDefaults(suiteName: suiteName)
        let baseData = readBaseData(defaults: defaults)
        let cachedWeather = readCachedWeather(defaults: defaults)
        completion(buildEntry(baseData: baseData, weather: cachedWeather))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TaskEntry>) -> Void) {
        let defaults = UserDefaults(suiteName: suiteName)
        let baseData = readBaseData(defaults: defaults)
        let cachedWeather = readCachedWeather(defaults: defaults)

        let complete: (WidgetWeatherSnapshot?) -> Void = { weather in
            let entry = buildEntry(baseData: baseData, weather: weather)
            let refresh = Calendar.current.date(
                byAdding: .minute,
                value: weatherRefreshMinutes,
                to: Date()
            ) ?? Date().addingTimeInterval(TimeInterval(weatherRefreshMinutes * 60))
            completion(Timeline(entries: [entry], policy: .after(refresh)))
        }

        guard shouldAttemptWeatherRefresh(cachedWeather) else {
            complete(cachedWeather)
            return
        }

        WidgetWeatherFetcher.fetchIfPossible(suiteName: suiteName) { refreshedWeather in
            complete(refreshedWeather ?? cachedWeather)
        }
    }

    private func readBaseData(defaults: UserDefaults?) -> WidgetBaseData {
        let greeting = defaults?.string(forKey: "greeting") ?? "Good day"
        let dateLabel = defaults?.string(forKey: "date_label") ?? ""
        let taskCountToday = defaults?.integer(forKey: "task_count_today") ?? 0
        let tasksCompletedToday = defaults?.integer(forKey: "tasks_completed_today") ?? 0
        let overdueCount = defaults?.integer(forKey: "overdue_count") ?? 0
        let nextTasksJson = defaults?.string(forKey: "next_tasks_json") ?? "[]"

        return WidgetBaseData(
            greeting: greeting,
            dateLabel: dateLabel,
            taskCountToday: taskCountToday,
            tasksCompletedToday: tasksCompletedToday,
            nextTasks: parseTasksJson(nextTasksJson),
            overdueCount: overdueCount
        )
    }

    private func parseTasksJson(_ json: String) -> [(title: String, alarm: String?)] {
        guard
            let data = json.data(using: .utf8),
            let array = try? JSONSerialization.jsonObject(with: data) as? [[String: Any?]]
        else {
            return []
        }

        return array.compactMap { object in
            guard let title = object["title"] as? String, !title.isEmpty else {
                return nil
            }
            return (title: title, alarm: object["alarm"] as? String)
        }
    }

    private func readCachedWeather(defaults: UserDefaults?) -> WidgetWeatherSnapshot? {
        guard
            let tempNumber = defaults?.object(forKey: "weather_temp_value") as? NSNumber,
            let weatherCodeNumber = defaults?.object(forKey: "weather_code") as? NSNumber,
            let updatedAtNumber = defaults?.object(forKey: "weather_updated_at") as? NSNumber
        else {
            return nil
        }

        return WidgetWeatherSnapshot(
            tempValue: tempNumber.intValue,
            weatherCode: weatherCodeNumber.intValue,
            updatedAt: Date(timeIntervalSince1970: updatedAtNumber.doubleValue / 1000)
        )
    }

    private func buildEntry(baseData: WidgetBaseData, weather: WidgetWeatherSnapshot?) -> TaskEntry {
        let state = weatherState(for: weather)
        return TaskEntry(
            date: Date(),
            greeting: baseData.greeting,
            dateLabel: baseData.dateLabel,
            taskCountToday: baseData.taskCountToday,
            tasksCompletedToday: baseData.tasksCompletedToday,
            nextTasks: baseData.nextTasks,
            overdueCount: baseData.overdueCount,
            weatherTempValue: weather?.tempValue,
            weatherCode: weather?.weatherCode,
            weatherUpdatedAt: weather?.updatedAt,
            weatherState: state
        )
    }

    private func weatherState(for weather: WidgetWeatherSnapshot?) -> WidgetWeatherState {
        guard let weather else { return .missing }
        let age = Date().timeIntervalSince(weather.updatedAt)
        return age <= TimeInterval(weatherRefreshMinutes * 60) ? .fresh : .stale
    }

    private func shouldAttemptWeatherRefresh(_ cachedWeather: WidgetWeatherSnapshot?) -> Bool {
        switch weatherState(for: cachedWeather) {
        case .missing, .stale:
            return true
        case .fresh:
            return false
        }
    }
}

private final class WidgetWeatherFetcher: NSObject, CLLocationManagerDelegate {
    private static var activeFetchers: [WidgetWeatherFetcher] = []

    private let suiteName: String
    private let defaults: UserDefaults?
    private let locationManager = CLLocationManager()

    private var completion: ((WidgetWeatherSnapshot?) -> Void)?
    private var timeoutWorkItem: DispatchWorkItem?
    private var didFinish = false

    private init(suiteName: String) {
        self.suiteName = suiteName
        self.defaults = UserDefaults(suiteName: suiteName)
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers
    }

    static func fetchIfPossible(
        suiteName: String,
        completion: @escaping (WidgetWeatherSnapshot?) -> Void
    ) {
        let fetcher = WidgetWeatherFetcher(suiteName: suiteName)
        activeFetchers.append(fetcher)
        fetcher.start { result in
            activeFetchers.removeAll { $0 === fetcher }
            completion(result)
        }
    }

    private func start(completion: @escaping (WidgetWeatherSnapshot?) -> Void) {
        self.completion = completion

        guard CLLocationManager.locationServicesEnabled() else {
            finish(with: nil)
            return
        }

        guard locationManager.isAuthorizedForWidgetUpdates else {
            finish(with: nil)
            return
        }

        let timeout = DispatchWorkItem { [weak self] in
            self?.finish(with: nil)
        }
        timeoutWorkItem = timeout
        DispatchQueue.main.asyncAfter(deadline: .now() + 6, execute: timeout)

        DispatchQueue.main.async { [weak self] in
            self?.locationManager.requestLocation()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else {
            finish(with: nil)
            return
        }

        fetchWeather(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        finish(with: nil)
    }

    private func fetchWeather(latitude: Double, longitude: Double) {
        guard let url = URL(string:
            "https://api.open-meteo.com/v1/forecast" +
            "?latitude=\(latitude)" +
            "&longitude=\(longitude)" +
            "&current=temperature_2m,weather_code" +
            "&timezone=auto"
        ) else {
            finish(with: nil)
            return
        }

        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let self else { return }

            guard
                error == nil,
                let response = response as? HTTPURLResponse,
                response.statusCode == 200,
                let data,
                let body = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                let current = body["current"] as? [String: Any],
                let tempNumber = current["temperature_2m"] as? NSNumber,
                let codeNumber = current["weather_code"] as? NSNumber
            else {
                self.finish(with: nil)
                return
            }

            let weather = WidgetWeatherSnapshot(
                tempValue: Int(tempNumber.doubleValue.rounded()),
                weatherCode: codeNumber.intValue,
                updatedAt: Date()
            )
            self.persist(weather)
            self.finish(with: weather)
        }.resume()
    }

    private func persist(_ weather: WidgetWeatherSnapshot) {
        defaults?.set(weather.tempValue, forKey: "weather_temp_value")
        defaults?.set(weather.weatherCode, forKey: "weather_code")
        defaults?.set(
            Int(weather.updatedAt.timeIntervalSince1970 * 1000),
            forKey: "weather_updated_at"
        )
        defaults?.set("\(weather.tempValue)°", forKey: "weather_temp")
    }

    private func finish(with weather: WidgetWeatherSnapshot?) {
        guard !didFinish else { return }
        didFinish = true
        timeoutWorkItem?.cancel()
        completion?(weather)
        completion = nil
    }
}

struct TaskWidgetEntryView: View {
    let entry: TaskEntry
    @Environment(\.widgetFamily) private var family

    private let bg = Color(red: 0.07, green: 0.07, blue: 0.07)
    private let panel = Color(red: 0.09, green: 0.09, blue: 0.09)
    private let accent = Color(red: 0.118, green: 0.894, blue: 0.408)
    private let border = Color.white.opacity(0.12)
    private let secondary = Color(red: 0.56, green: 0.58, blue: 0.56)
    private let muted = Color.white.opacity(0.8)

    private var dayNumber: String {
        entry.date.formatted(.dateTime.day())
    }

    private var weekday: String {
        entry.date.formatted(.dateTime.weekday(.wide))
    }

    private var monthDay: String {
        entry.date.formatted(.dateTime.month(.abbreviated).day())
    }

    private var taskCountLabel: String {
        entry.taskCountToday == 1 ? "1 task today" : "\(entry.taskCountToday) tasks today"
    }

    private var highlightedCountPhrase: String {
        entry.taskCountToday == 1 ? "1 task" : "\(entry.taskCountToday) tasks"
    }

    private var firstPendingTask: (title: String, alarm: String?)? {
        entry.nextTasks.first
    }

    private var weatherDisplay: (temperature: String, symbol: String, stale: Bool)? {
        guard family != .systemSmall else { return nil }
        guard
            entry.weatherState != .missing,
            let tempValue = entry.weatherTempValue,
            let weatherCode = entry.weatherCode
        else {
            return nil
        }

        return (
            temperature: "\(tempValue)°",
            symbol: weatherEmoji(weatherCode),
            stale: entry.weatherState == .stale
        )
    }

    private struct Metrics {
        let outerPadding: CGFloat
        let badgeSize: CGFloat
        let dayFont: CGFloat
        let weekdayFont: CGFloat
        let monthFont: CGFloat
        let countFont: CGFloat
        let weatherFont: CGFloat
        let weatherEmojiFont: CGFloat
        let greetingFont: CGFloat
        let headlineFont: CGFloat
        let topSectionSpacing: CGFloat
        let titleSpacing: CGFloat
        let cardHeight: CGFloat
        let cardHorizontalPadding: CGFloat
        let cardSpacing: CGFloat
        let circleSize: CGFloat
        let taskFont: CGFloat
        let alarmFont: CGFloat
        let footerTopSpacing: CGFloat
        let summaryFont: CGFloat
        let cornerRadius: CGFloat
        let cardRadius: CGFloat
        let headlineLineLimit: Int
    }

    private let regular = Metrics(
        outerPadding: 14,
        badgeSize: 44,
        dayFont: 22,
        weekdayFont: 17,
        monthFont: 11,
        countFont: 11,
        weatherFont: 20,
        weatherEmojiFont: 18,
        greetingFont: 17,
        headlineFont: 14,
        topSectionSpacing: 10,
        titleSpacing: 2,
        cardHeight: 50,
        cardHorizontalPadding: 12,
        cardSpacing: 10,
        circleSize: 16,
        taskFont: 14,
        alarmFont: 10,
        footerTopSpacing: 8,
        summaryFont: 10,
        cornerRadius: 24,
        cardRadius: 16,
        headlineLineLimit: 1
    )

    private let compact = Metrics(
        outerPadding: 12,
        badgeSize: 40,
        dayFont: 20,
        weekdayFont: 15,
        monthFont: 9,
        countFont: 10,
        weatherFont: 18,
        weatherEmojiFont: 16,
        greetingFont: 15,
        headlineFont: 13,
        topSectionSpacing: 8,
        titleSpacing: 1,
        cardHeight: 45,
        cardHorizontalPadding: 10,
        cardSpacing: 8,
        circleSize: 14,
        taskFont: 13,
        alarmFont: 9,
        footerTopSpacing: 7,
        summaryFont: 9,
        cornerRadius: 22,
        cardRadius: 14,
        headlineLineLimit: 1
    )

    private let smallRegular = Metrics(
        outerPadding: 12,
        badgeSize: 36,
        dayFont: 18,
        weekdayFont: 14,
        monthFont: 9,
        countFont: 10,
        weatherFont: 16,
        weatherEmojiFont: 14,
        greetingFont: 13,
        headlineFont: 12,
        topSectionSpacing: 8,
        titleSpacing: 1,
        cardHeight: 40,
        cardHorizontalPadding: 10,
        cardSpacing: 8,
        circleSize: 13,
        taskFont: 12,
        alarmFont: 8,
        footerTopSpacing: 7,
        summaryFont: 8,
        cornerRadius: 22,
        cardRadius: 14,
        headlineLineLimit: 2
    )

    private let smallCompact = Metrics(
        outerPadding: 10,
        badgeSize: 32,
        dayFont: 16,
        weekdayFont: 13,
        monthFont: 8,
        countFont: 9,
        weatherFont: 15,
        weatherEmojiFont: 13,
        greetingFont: 12,
        headlineFont: 11,
        topSectionSpacing: 6,
        titleSpacing: 1,
        cardHeight: 36,
        cardHorizontalPadding: 9,
        cardSpacing: 7,
        circleSize: 12,
        taskFont: 11,
        alarmFont: 8,
        footerTopSpacing: 6,
        summaryFont: 8,
        cornerRadius: 20,
        cardRadius: 12,
        headlineLineLimit: 2
    )

    var body: some View {
        widgetShell {
            switch family {
            case .systemSmall:
                if firstPendingTask != nil {
                    ViewThatFits(in: .vertical) {
                        taskWidgetContent(metrics: smallRegular)
                        taskWidgetContent(metrics: smallCompact)
                    }
                } else {
                    ViewThatFits(in: .vertical) {
                        emptyWidgetContent(metrics: smallRegular)
                        emptyWidgetContent(metrics: smallCompact)
                    }
                }
            default:
                if firstPendingTask != nil {
                    ViewThatFits(in: .vertical) {
                        taskWidgetContent(metrics: regular)
                        taskWidgetContent(metrics: compact)
                    }
                } else {
                    ViewThatFits(in: .vertical) {
                        emptyWidgetContent(metrics: regular)
                        emptyWidgetContent(metrics: compact)
                    }
                }
            }
        }
        .widgetURL(URL(string: "taskapp://home"))
    }

    @ViewBuilder
    private func widgetShell<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        let radius = family == .systemSmall ? smallRegular.cornerRadius : regular.cornerRadius

        ZStack {
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .fill(bg)

            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .strokeBorder(border, lineWidth: 1)

            LinearGradient(
                colors: [
                    accent.opacity(0.10),
                    accent.opacity(0.03),
                    .clear,
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))

            content()
        }
    }

    @ViewBuilder
    private func taskWidgetContent(metrics: Metrics) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            header(metrics: metrics)

            Spacer(minLength: metrics.topSectionSpacing + 2)

            if let task = firstPendingTask {
                HStack(spacing: metrics.cardSpacing) {
                    Circle()
                        .strokeBorder(secondary, lineWidth: 2)
                        .frame(width: metrics.circleSize, height: metrics.circleSize)

                    Text(task.title)
                        .font(.system(size: metrics.taskFont, weight: .medium, design: .rounded))
                        .foregroundColor(muted)
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)

                    Spacer(minLength: 6)

                    if let alarm = task.alarm {
                        Text(alarm)
                            .font(.system(size: metrics.alarmFont, weight: .semibold, design: .rounded))
                            .foregroundColor(accent)
                            .lineLimit(1)
                            .minimumScaleFactor(0.72)
                    }
                }
                .padding(.horizontal, metrics.cardHorizontalPadding)
                .frame(height: metrics.cardHeight)
                .background(
                    RoundedRectangle(cornerRadius: metrics.cardRadius, style: .continuous)
                        .fill(panel)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: metrics.cardRadius, style: .continuous)
                        .strokeBorder(border, lineWidth: 1)
                )
            }

            summary(metrics: metrics)
                .padding(.top, metrics.footerTopSpacing)
        }
        .padding(metrics.outerPadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    @ViewBuilder
    private func emptyWidgetContent(metrics: Metrics) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            header(metrics: metrics)

            Spacer(minLength: metrics.topSectionSpacing + 4)

            Text(entry.taskCountToday == 0 ? "No tasks for today" : "All tasks completed")
                .font(.system(size: metrics.headlineFont, weight: .medium, design: .rounded))
                .foregroundColor(secondary)
                .lineLimit(1)

            summary(metrics: metrics)
                .padding(.top, metrics.footerTopSpacing)
        }
        .padding(metrics.outerPadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    @ViewBuilder
    private func header(metrics: Metrics) -> some View {
        HStack(alignment: .center, spacing: 0) {
            ZStack {
                Circle()
                    .fill(accent)

                Text(dayNumber)
                    .font(.system(size: metrics.dayFont, weight: .bold, design: .rounded))
                    .foregroundColor(Color(red: 0.03, green: 0.09, blue: 0.05))
            }
            .frame(width: metrics.badgeSize, height: metrics.badgeSize)

            VStack(alignment: .leading, spacing: 1) {
                Text(weekday)
                    .font(.system(size: metrics.weekdayFont, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .lineLimit(1)

                Text(monthDay)
                    .font(.system(size: metrics.monthFont, weight: .medium, design: .rounded))
                    .foregroundColor(secondary)
            }
            .padding(.leading, metrics.cardSpacing)

            Spacer(minLength: 6)

            if family != .systemSmall {
                if let weatherDisplay {
                    HStack(alignment: .center, spacing: 3) {
                        Text(weatherDisplay.temperature)
                            .font(.system(size: metrics.weatherFont, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)

                        Text(weatherDisplay.symbol)
                            .font(.system(size: metrics.weatherEmojiFont))
                    }
                    .opacity(weatherDisplay.stale ? 0.68 : 1)
                } else {
                    Text(taskCountLabel)
                        .font(.system(size: metrics.countFont, weight: .semibold, design: .rounded))
                        .foregroundColor(accent)
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                }
            }
        }

        Text(entry.greeting)
            .font(.system(size: metrics.greetingFont, weight: .bold, design: .rounded))
            .foregroundColor(.white)
            .lineLimit(1)
            .padding(.top, metrics.topSectionSpacing)

        (
            Text("You have ")
                .foregroundColor(.white)
            + Text(highlightedCountPhrase)
                .foregroundColor(accent)
            + Text(" today.")
                .foregroundColor(.white)
        )
        .font(.system(size: metrics.headlineFont, weight: .medium, design: .rounded))
        .lineLimit(metrics.headlineLineLimit)
        .minimumScaleFactor(0.72)
        .padding(.top, metrics.titleSpacing)
    }

    @ViewBuilder
    private func summary(metrics: Metrics) -> some View {
        Text("✓ \(entry.tasksCompletedToday) of \(entry.taskCountToday) done")
            .font(.system(size: metrics.summaryFont, weight: .medium, design: .rounded))
            .foregroundColor(secondary)
    }

    private func weatherEmoji(_ code: Int) -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        let isNight = hour < 6 || hour >= 20

        switch code {
        case 0:
            return isNight ? "🌙" : "☀️"
        case 1:
            return isNight ? "🌙" : "🌤️"
        case 2:
            return "⛅"
        case 3:
            return "☁️"
        case 45, 48:
            return "🌫️"
        case 51, 53, 55:
            return "🌦️"
        case 56, 57, 61, 63, 65, 80, 81, 82:
            return "🌧️"
        case 66, 67:
            return "🧊"
        case 71, 73, 75, 77, 85, 86:
            return "🌨️"
        case 95, 96, 99:
            return "⛈️"
        default:
            return "☁️"
        }
    }
}

struct TaskWidget: Widget {
    let kind: String = "TaskWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TaskProvider()) { entry in
            if #available(iOS 17.0, *) {
                TaskWidgetEntryView(entry: entry)
                    .containerBackground(Color.clear, for: .widget)
            } else {
                TaskWidgetEntryView(entry: entry)
            }
        }
        .contentMarginsDisabled()
        .configurationDisplayName("Today's Tasks")
        .description("See your tasks at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
