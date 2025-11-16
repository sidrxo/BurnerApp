"use client";

import { useEffect, useState } from "react";
import { useParams, useRouter } from "next/navigation";
import { doc, getDoc } from "firebase/firestore";
import { httpsCallable } from "firebase/functions";
import { db, functions } from "@/lib/firebase";
import { Event } from "@/hooks/usePublicEvents";
import { useAuth } from "@/components/useAuth";
import { loadStripe } from "@stripe/stripe-js";
import {
  Elements,
  PaymentElement,
  useStripe,
  useElements,
} from "@stripe/react-stripe-js";
import { toast } from "sonner";
import Image from "next/image";

const stripePromise = loadStripe(
  process.env.NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY || ""
);

function CheckoutForm({
  event,
  clientSecret,
  onSuccess,
}: {
  event: Event;
  clientSecret: string;
  onSuccess: () => void;
}) {
  const stripe = useStripe();
  const elements = useElements();
  const [loading, setLoading] = useState(false);

  const formatPrice = (price: number) => {
    return new Intl.NumberFormat("en-GB", {
      style: "currency",
      currency: "GBP",
    }).format(price / 100);
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    if (!stripe || !elements) {
      return;
    }

    setLoading(true);

    try {
      const { error: submitError } = await elements.submit();
      if (submitError) {
        toast.error(submitError.message);
        setLoading(false);
        return;
      }

      const { error, paymentIntent } = await stripe.confirmPayment({
        elements,
        clientSecret,
        confirmParams: {
          return_url: `${window.location.origin}/my-tickets`,
        },
        redirect: "if_required",
      });

      if (error) {
        console.error('Payment error:', error);
        toast.error(error.message || "Payment failed");
        setLoading(false);
        return;
      }

      if (paymentIntent && paymentIntent.status === "succeeded") {
        // Call confirmPurchase Cloud Function using Firebase SDK
        const confirmPurchase = httpsCallable(functions, "confirmPurchase");
        
        try {
          await confirmPurchase({ paymentIntentId: paymentIntent.id });
          toast.success("Ticket purchased successfully!");
          onSuccess();
        } catch (confirmError) {
          console.error('Error confirming purchase:', confirmError);
          toast.error("Payment succeeded but ticket creation failed. Please contact support.");
        }
      }
    } catch (err: any) {
      console.error("Payment error:", err);
      toast.error(err.message || "Payment failed");
    } finally {
      setLoading(false);
    }
  };

  return (
    <form onSubmit={handleSubmit} className="space-y-6">
      {/* Your existing form JSX */}
      <div className="bg-white/5 border border-white/10 rounded-xl p-6">
        <div className="flex items-center justify-between mb-4">
          <span className="text-white/70">Total</span>
          <span className="text-3xl font-bold">{formatPrice(event.price)}</span>
        </div>
        <div className="text-white/50 text-sm">
          <p>{event.name}</p>
          <p>{event.venue}</p>
        </div>
      </div>

      <div className="bg-white/5 border border-white/10 rounded-xl p-6 min-h-[200px]">
        <PaymentElement
          options={{
            layout: {
              type: 'tabs',
              defaultCollapsed: false,
            }
          }}
        />
      </div>

      <p className="text-white/30 text-sm text-center">
        By purchasing a ticket, you agree to our{" "}
        <a href="/terms" className="underline hover:text-white/50">
          Terms of Service
        </a>{" "}
        and{" "}
        <a href="/privacy" className="underline hover:text-white/50">
          Privacy Policy
        </a>
      </p>

      <button
        type="submit"
        disabled={!stripe || loading}
        className={`
          w-full py-4 rounded-xl font-bold text-lg transition-all duration-300
          ${
            loading || !stripe
              ? "bg-white/10 text-white/30 cursor-not-allowed"
              : "bg-white text-black hover:bg-white/90"
          }
        `}
      >
        {loading ? "Processing..." : `Pay ${formatPrice(event.price)}`}
      </button>
    </form>
  );
}

export default function PurchasePage() {
  const params = useParams();
  const router = useRouter();
  const { user, loading: authLoading } = useAuth();
  const [event, setEvent] = useState<Event | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [clientSecret, setClientSecret] = useState<string | null>(null);

  useEffect(() => {
    if (authLoading) return;

    if (!user) {
      router.push(`/signin?return=/events/${params.eventId}/purchase`);
      return;
    }

    const initPurchase = async () => {
      try {
        setLoading(true);
        setError(null);

        // Fetch event
        const eventDoc = await getDoc(doc(db, "events", params.eventId as string));

        if (!eventDoc.exists()) {
          setError("Event not found");
          return;
        }

        const eventData = { id: eventDoc.id, ...eventDoc.data() } as Event;
        setEvent(eventData);

        // Create payment intent using Firebase SDK
        const createPaymentIntent = httpsCallable(functions, "createPaymentIntent");
        
        const result = await createPaymentIntent({ 
          eventId: params.eventId 
        });
        
        const data = result.data as { clientSecret: string };
        setClientSecret(data.clientSecret);
      } catch (err: any) {
        console.error("Error initializing purchase:", err);
        
        // Handle different types of Firebase errors
        if (err.code === 'functions/unauthenticated') {
          setError("Please sign in to continue");
          router.push(`/signin?return=/events/${params.eventId}/purchase`);
        } else if (err.code === 'functions/not-found') {
          setError("Event not found");
        } else {
          setError(err.message || "Failed to initialize purchase");
        }
        
        toast.error(err.message || "Failed to initialize purchase");
      } finally {
        setLoading(false);
      }
    };

    initPurchase();
  }, [params.eventId, user, authLoading, router]);

  const handleSuccess = () => {
    router.push("/my-tickets");
  };

  // Rest of your component JSX remains the same...
  if (authLoading || loading) {
    return (
      <div className="flex items-center justify-center min-h-screen">
        <div className="text-center space-y-4">
          <div className="w-8 h-8 border-2 border-white/20 border-t-white rounded-full animate-spin mx-auto" />
          <p className="text-white/50">Loading...</p>
        </div>
      </div>
    );
  }

  if (error || !event || !clientSecret) {
    return (
      <div className="flex items-center justify-center min-h-screen px-4">
        <div className="text-center space-y-4">
          <p className="text-white/70">{error || "Failed to load purchase page"}</p>
          <button
            onClick={() => router.push(`/events/${params.eventId}`)}
            className="px-6 py-2 bg-white text-black rounded-lg font-medium hover:bg-white/90 transition-colors"
          >
            Back to Event
          </button>
        </div>
      </div>
    );
  }

  const options = {
    clientSecret,
    appearance: {
      theme: "night" as const,
      variables: {
        colorPrimary: "#ffffff",
        colorBackground: "#1a1a1a",
        colorText: "#ffffff",
        colorDanger: "#ef4444",
        fontFamily: "system-ui, -apple-system, sans-serif",
        borderRadius: "12px",
        spacingUnit: "4px",
        fontSizeBase: "16px",
      },
      rules: {
        '.Input': {
          backgroundColor: '#2a2a2a',
          border: '1px solid rgba(255, 255, 255, 0.1)',
          padding: '12px',
          color: '#ffffff',
        },
        '.Input:focus': {
          border: '1px solid rgba(255, 255, 255, 0.3)',
          boxShadow: 'none',
        },
        '.Label': {
          color: '#ffffff',
          fontWeight: '500',
          marginBottom: '8px',
        },
        '.Tab': {
          border: '1px solid rgba(255, 255, 255, 0.1)',
          backgroundColor: '#1a1a1a',
        },
        '.Tab--selected': {
          border: '1px solid rgba(255, 255, 255, 0.3)',
          backgroundColor: '#2a2a2a',
        },
      },
    },
  };

  return (
    <div className="min-h-screen pb-12">
      {/* Back Button */}
      <div className="px-4 py-4 max-w-2xl mx-auto">
        <button
          onClick={() => router.back()}
          className="flex items-center gap-2 text-white/70 hover:text-white transition-colors"
        >
          <svg
            className="w-5 h-5"
            fill="none"
            stroke="currentColor"
            viewBox="0 0 24 24"
          >
            <path
              strokeLinecap="round"
              strokeLinejoin="round"
              strokeWidth={2}
              d="M15 19l-7-7 7-7"
            />
          </svg>
          Back
        </button>
      </div>

      {/* Purchase Form */}
      <div className="px-4 max-w-2xl mx-auto space-y-6">
        <h1 className="text-3xl md:text-4xl font-bold">Complete Purchase</h1>

        {/* Event Summary */}
        {event.imageUrl && (
          <div className="relative w-full h-32 rounded-xl overflow-hidden">
            <Image
              src={event.imageUrl}
              alt={event.name}
              fill
              className="object-cover"
            />
          </div>
        )}

        {/* Stripe Payment Form */}
        <Elements stripe={stripePromise} options={options}>
          <CheckoutForm
            event={event}
            clientSecret={clientSecret}
            onSuccess={handleSuccess}
          />
        </Elements>
      </div>
    </div>
  );
}