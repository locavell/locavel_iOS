import SwiftUI

struct StartView: View {
    
    @State private var isLaunching: Bool = true
    
    var body: some View {
        NavigationView {
            if isLaunching {
                SplashView()
                    .opacity(isLaunching ? 1 : 0)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            withAnimation(.easeIn(duration: 1)) {
                                isLaunching = false
                            }
                        }
                    }
            } else {
                NavigationLink(destination: LogInView()) {
                    Text("시작하기")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .foregroundColor(.white)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .frame(width: 281, height: 51)
                        )
                }
                .padding()
            }
        }
    }
}

#Preview {
    StartView()
}
