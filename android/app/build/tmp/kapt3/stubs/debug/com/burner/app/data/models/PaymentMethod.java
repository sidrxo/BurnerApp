package com.burner.app.data.models;

@kotlin.Metadata(mv = {1, 9, 0}, k = 1, xi = 48, d1 = {"\u0000\u001a\n\u0002\u0018\u0002\n\u0002\u0010\u0000\n\u0002\b\u0004\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0000\b6\u0018\u00002\u00020\u0001:\u0003\u0003\u0004\u0005B\u0007\b\u0004\u00a2\u0006\u0002\u0010\u0002\u0082\u0001\u0003\u0006\u0007\b\u00a8\u0006\t"}, d2 = {"Lcom/burner/app/data/models/PaymentMethod;", "", "()V", "Card", "GooglePay", "NewCard", "Lcom/burner/app/data/models/PaymentMethod$Card;", "Lcom/burner/app/data/models/PaymentMethod$GooglePay;", "Lcom/burner/app/data/models/PaymentMethod$NewCard;", "app_debug"})
public abstract class PaymentMethod {
    
    private PaymentMethod() {
        super();
    }
    
    @kotlin.Metadata(mv = {1, 9, 0}, k = 1, xi = 48, d1 = {"\u0000*\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0002\b\u0006\n\u0002\u0010\u000b\n\u0000\n\u0002\u0010\u0000\n\u0000\n\u0002\u0010\b\n\u0000\n\u0002\u0010\u000e\n\u0000\b\u0086\b\u0018\u00002\u00020\u0001B\u0011\u0012\n\b\u0002\u0010\u0002\u001a\u0004\u0018\u00010\u0003\u00a2\u0006\u0002\u0010\u0004J\u000b\u0010\u0007\u001a\u0004\u0018\u00010\u0003H\u00c6\u0003J\u0015\u0010\b\u001a\u00020\u00002\n\b\u0002\u0010\u0002\u001a\u0004\u0018\u00010\u0003H\u00c6\u0001J\u0013\u0010\t\u001a\u00020\n2\b\u0010\u000b\u001a\u0004\u0018\u00010\fH\u00d6\u0003J\t\u0010\r\u001a\u00020\u000eH\u00d6\u0001J\t\u0010\u000f\u001a\u00020\u0010H\u00d6\u0001R\u0013\u0010\u0002\u001a\u0004\u0018\u00010\u0003\u00a2\u0006\b\n\u0000\u001a\u0004\b\u0005\u0010\u0006\u00a8\u0006\u0011"}, d2 = {"Lcom/burner/app/data/models/PaymentMethod$Card;", "Lcom/burner/app/data/models/PaymentMethod;", "savedCard", "Lcom/burner/app/data/models/SavedCard;", "(Lcom/burner/app/data/models/SavedCard;)V", "getSavedCard", "()Lcom/burner/app/data/models/SavedCard;", "component1", "copy", "equals", "", "other", "", "hashCode", "", "toString", "", "app_debug"})
    public static final class Card extends com.burner.app.data.models.PaymentMethod {
        @org.jetbrains.annotations.Nullable()
        private final com.burner.app.data.models.SavedCard savedCard = null;
        
        public Card(@org.jetbrains.annotations.Nullable()
        com.burner.app.data.models.SavedCard savedCard) {
        }
        
        @org.jetbrains.annotations.Nullable()
        public final com.burner.app.data.models.SavedCard getSavedCard() {
            return null;
        }
        
        public Card() {
        }
        
        @org.jetbrains.annotations.Nullable()
        public final com.burner.app.data.models.SavedCard component1() {
            return null;
        }
        
        @org.jetbrains.annotations.NotNull()
        public final com.burner.app.data.models.PaymentMethod.Card copy(@org.jetbrains.annotations.Nullable()
        com.burner.app.data.models.SavedCard savedCard) {
            return null;
        }
        
        @java.lang.Override()
        public boolean equals(@org.jetbrains.annotations.Nullable()
        java.lang.Object other) {
            return false;
        }
        
        @java.lang.Override()
        public int hashCode() {
            return 0;
        }
        
        @java.lang.Override()
        @org.jetbrains.annotations.NotNull()
        public java.lang.String toString() {
            return null;
        }
    }
    
    @kotlin.Metadata(mv = {1, 9, 0}, k = 1, xi = 48, d1 = {"\u0000\f\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\b\u0002\b\u00c6\u0002\u0018\u00002\u00020\u0001B\u0007\b\u0002\u00a2\u0006\u0002\u0010\u0002\u00a8\u0006\u0003"}, d2 = {"Lcom/burner/app/data/models/PaymentMethod$GooglePay;", "Lcom/burner/app/data/models/PaymentMethod;", "()V", "app_debug"})
    public static final class GooglePay extends com.burner.app.data.models.PaymentMethod {
        @org.jetbrains.annotations.NotNull()
        public static final com.burner.app.data.models.PaymentMethod.GooglePay INSTANCE = null;
        
        private GooglePay() {
        }
    }
    
    @kotlin.Metadata(mv = {1, 9, 0}, k = 1, xi = 48, d1 = {"\u0000\f\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\b\u0002\b\u00c6\u0002\u0018\u00002\u00020\u0001B\u0007\b\u0002\u00a2\u0006\u0002\u0010\u0002\u00a8\u0006\u0003"}, d2 = {"Lcom/burner/app/data/models/PaymentMethod$NewCard;", "Lcom/burner/app/data/models/PaymentMethod;", "()V", "app_debug"})
    public static final class NewCard extends com.burner.app.data.models.PaymentMethod {
        @org.jetbrains.annotations.NotNull()
        public static final com.burner.app.data.models.PaymentMethod.NewCard INSTANCE = null;
        
        private NewCard() {
        }
    }
}